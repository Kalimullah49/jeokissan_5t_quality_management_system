"""
Firebase Cloud Function (2nd Gen) for Secure Gemini AI Commodity Classification.

This function replaces direct client-side API calls, providing:
1. Authentication enforcement (only logged-in users)
2. Secure API key management via Firebase Secret Manager
3. Server-side API calls to OpenRouter (prevents CORS, API key exposure)
4. Structured error handling and logging

Deploy with:
  firebase deploy --only functions
"""

import json
import os
import requests
from typing import Any, Dict

import functions_framework
from firebase_functions import https_fn
from google.cloud import secretmanager


# ─── Global Configuration ───────────────────────────────────────────────────

OPENROUTER_MODEL = "google/gemini-2.0-flash-001"
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1/chat/completions"
SECRET_MANAGER_PROJECT = os.environ.get("GCLOUD_PROJECT")
OPENROUTER_KEY_SECRET = "OPENROUTER_KEY_1"


# ─── Secret Manager: Fetch API Key Securely ────────────────────────────────

_cached_api_key: str | None = None


def _get_openrouter_api_key() -> str:
    """
    Fetch the OpenRouter API key from Firebase Secret Manager.
    Uses in-memory caching to avoid repeated API calls.
    """
    global _cached_api_key

    if _cached_api_key:
        return _cached_api_key

    try:
        client = secretmanager.SecretManagerServiceClient()
        project_id = SECRET_MANAGER_PROJECT or os.environ.get("GCP_PROJECT")
        if not project_id:
            raise ValueError("GCP_PROJECT environment variable not set")

        secret_path = client.secret_version_path(
            project_id, OPENROUTER_KEY_SECRET, "latest"
        )
        response = client.access_secret_version(request={"name": secret_path})
        _cached_api_key = response.payload.data.decode("UTF-8")
        return _cached_api_key
    except Exception as e:
        raise RuntimeError(
            f"Failed to fetch OpenRouter API key from Secret Manager: {str(e)}"
        ) from e


# ─── OpenRouter API Call ────────────────────────────────────────────────────


def _call_openrouter_api(
    messages: list[Dict[str, Any]], max_tokens: int = 700, temperature: float = 0.2
) -> str:
    """
    Make an authenticated POST request to OpenRouter API.

    Args:
        messages: OpenAI-compatible messages array
        max_tokens: Maximum tokens in response
        temperature: Sampling temperature (0.0-2.0)

    Returns:
        Message content string from the API response

    Raises:
        RuntimeError: If API call fails
    """
    api_key = _get_openrouter_api_key()

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://jeokissan-quality-manual.web.app",
        "X-Title": "JeoKissan QMS",
    }

    payload = {
        "model": OPENROUTER_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }

    try:
        response = requests.post(
            OPENROUTER_BASE_URL, headers=headers, json=payload, timeout=60
        )
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        raise RuntimeError(
            f"OpenRouter API request failed: {str(e)}. Status: {getattr(e.response, 'status_code', 'N/A')}"
        ) from e

    try:
        response_data = response.json()
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse OpenRouter response: {str(e)}") from e

    choices = response_data.get("choices", [])
    if not choices:
        raise RuntimeError(f"No response choices from OpenRouter: {response_data}")

    message = choices[0].get("message", {})
    content = message.get("content", "")
    if not content:
        raise RuntimeError(f"Empty message content from OpenRouter: {response_data}")

    return content


# ─── JSON Parsing Helper ────────────────────────────────────────────────────


def _parse_json_from_response(text: str) -> Dict[str, Any]:
    """
    Extract and parse JSON from model response (with markdown cleanup).

    Args:
        text: Raw response text from model

    Returns:
        Parsed JSON dictionary

    Raises:
        ValueError: If no valid JSON found
    """
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try extracting JSON from markdown code fences
        first_brace = text.find("{")
        last_brace = text.rfind("}")
        if first_brace != -1 and last_brace > first_brace:
            try:
                json_str = text[first_brace : last_brace + 1]
                return json.loads(json_str)
            except json.JSONDecodeError:
                pass

        raise ValueError(f"Failed to parse JSON from response: {text}")


# ─── Cloud Function: Analyze & Ask Questions ───────────────────────────────


@https_fn.on_call
def analyze_and_ask_questions(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    STEP 1: Analyze image(s) and generate follow-up questions.

    Expected request data:
    {
        "base64_images": ["data:image/jpeg;base64,...", ...],
        "language_code": "en" | "ur"
    }

    Returns:
    {
        "commodity": "string",
        "preliminary_assessment": "string",
        "questions": [
            {
                "id": 1,
                "question": "string",
                "type": "dropdown",
                "options": ["option1", "option2", ...]
            },
            ...
        ]
    }

    Raises:
        https_fn.HttpsError: If auth fails, data invalid, or API fails
    """

    # ── Authentication Check ──────────────────────────────────────────────
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User must be authenticated to call this function.",
        )

    # ── Validate Input ───────────────────────────────────────────────────
    try:
        data = req.data
        if not isinstance(data, dict):
            raise ValueError("Request data must be a dictionary")

        base64_images = data.get("base64_images", [])
        if not base64_images or not isinstance(base64_images, list):
            raise ValueError(
                "Missing or invalid 'base64_images' array in request data"
            )

        language_code = data.get("language_code", "en")
        if language_code not in ("en", "ur"):
            language_code = "en"

    except (TypeError, KeyError) as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Invalid request data: {str(e)}",
        ) from e

    # ── Build System Prompt ──────────────────────────────────────────────
    language_label = "Urdu (اردو)" if language_code == "ur" else "English"
    not_ag_message = (
        "یہ تصویر زرعی اجناس پر مشتمل نہیں ہے۔ براہ کرم پھل، سبزی، اناج، دال، مصالحے، یا دیگر زرعی پیداوار کی تصویر اپ لوڈ کریں۔"
        if language_code == "ur"
        else "This image does not contain an agricultural commodity. Please upload an image of a fruit, vegetable, grain, pulse, spice, or other farm produce."
    )

    system_prompt = f"""You are an expert post-harvest quality analyst for agricultural commodities.

RESPONSE LANGUAGE: {language_label}

CRITICAL RULE: You MUST ONLY process images of AGRICULTURAL COMMODITIES such as:
- Fruits (mango, apple, banana, grapes, citrus, etc.)
- Vegetables (tomato, potato, onion, carrot, spinach, etc.)
- Grains & Cereals (wheat, rice, maize, barley, etc.)
- Pulses & Legumes (lentils, chickpeas, beans, etc.)
- Spices (turmeric, chili, cumin, coriander, etc.)
- Nuts & Dry Fruits (almonds, cashews, raisins, dates, etc.)
- Oilseeds (mustard, sunflower, soybean, etc.)
- Other farm produce (sugarcane, cotton, jute, tea leaves, etc.)

If the image does NOT contain an agricultural commodity (e.g., it shows a person, animal, vehicle, building, electronics, clothing, or any non-agricultural item), you MUST respond with ONLY this JSON:
{{"error": "NOT_AGRICULTURAL", "message": "{not_ag_message}"}}

Do NOT process, analyze, or classify any non-agricultural image under any circumstances.

If the image IS an agricultural commodity, look at {'ALL the images' if len(base64_images) > 1 else 'the image'} carefully and:
1. Identify what commodity it is
2. Do a preliminary visual assessment based on {'all images combined' if len(base64_images) > 1 else 'the image'}
3. Generate 4-5 follow-up questions STRICTLY about the PHYSICAL ATTRIBUTES of the commodity that you cannot fully determine from the {'images' if len(base64_images) > 1 else 'image'} alone

The questions MUST ONLY be about physical/sensory characteristics such as:
- Firmness or softness when touched/pressed
- Smell or aroma (fresh, sour, fermented, no smell, etc.)
- Weight or heaviness compared to normal
- Texture of the skin/surface (smooth, rough, sticky, dry, slimy)
- Internal colour or flesh condition (if cut open)
- Presence of any hidden spots, holes, or damage underneath
- Juiciness or moisture level
- Seed/pit condition
- Any unusual taste (if tasted)
- Physical size compared to standard for this commodity

DO NOT ask about storage, transport, harvest date, chemical treatment, origin, intended use, or any non-physical attributes.

Output ONLY a valid JSON object — no markdown, no code fences (in {language_label}):
{{
  "commodity": "<detected commodity name>",
  "preliminary_assessment": "<1-2 sentence visual assessment>",
  "questions": [
    {{"id": 1, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]}},
    {{"id": 2, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]}},
    {{"id": 3, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]}},
    {{"id": 4, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3", "option4"]}},
    {{"id": 5, "question": "<question text>", "type": "dropdown", "options": ["option1", "option2", "option3"]}}
  ]
}}

IMPORTANT: Every question MUST have "type": "dropdown" and an "options" array with 3-5 relevant answer choices. Make options specific and descriptive for the commodity. {'تمام سوالات اور جوابات اردو میں ہوں۔' if language_code == 'ur' else 'All questions and answers must be in the specified language.'}"""

    # ── Build Content Parts (Text + Images) ───────────────────────────────
    image_count_text = (
        f"these {len(base64_images)} images of the same commodity"
        if len(base64_images) > 1
        else "this commodity image"
    )
    content_parts = [
        {
            "type": "text",
            "text": f"Analyze {image_count_text} and generate follow-up questions to help determine its quality tier accurately. Return ONLY valid JSON.",
        }
    ]

    for base64_image in base64_images:
        content_parts.append(
            {
                "type": "image_url",
                "image_url": {"url": base64_image},
            }
        )

    # ── Build Messages Array ─────────────────────────────────────────────
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": content_parts},
    ]

    # ── Call OpenRouter API ──────────────────────────────────────────────
    try:
        response_text = _call_openrouter_api(messages, max_tokens=700, temperature=0.2)
    except RuntimeError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"OpenRouter API error: {str(e)}",
        ) from e

    # ── Parse and Validate Response ──────────────────────────────────────
    try:
        parsed = _parse_json_from_response(response_text)
    except ValueError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to parse API response: {str(e)}",
        ) from e

    # ── Check for Non-Agricultural Image ─────────────────────────────────
    if parsed.get("error") == "NOT_AGRICULTURAL":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=parsed.get(
                "message",
                "This is not an agricultural commodity image. Please upload a fruit, vegetable, grain, or other farm produce.",
            ),
        )

    # ── Validate Required Fields ─────────────────────────────────────────
    if "questions" not in parsed:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message='Missing "questions" field in API response',
        )

    return parsed


# ─── Cloud Function: Classify with Answers ─────────────────────────────────


@https_fn.on_call
def classify_with_answers(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    STEP 2: Final quality classification using image(s) + user answers.

    Expected request data:
    {
        "base64_images": ["data:image/jpeg;base64,...", ...],
        "commodity": "string",
        "questions_and_answers": [
            {"question": "Q text", "answer": "A text"},
            ...
        ],
        "language_code": "en" | "ur"
    }

    Returns:
    {
        "tier": "Excellent | Very Good | Good | Satisfactory | Unsatisfactory",
        "confidence": 0.95,
        "commodity": "string",
        "reasons": ["reason1", "reason2", ...],
        "corrective_actions": ["action1", "action2", ...],
        "notes": "string or empty"
    }

    Raises:
        https_fn.HttpsError: If auth fails, data invalid, or API fails
    """

    # ── Authentication Check ──────────────────────────────────────────────
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User must be authenticated to call this function.",
        )

    # ── Validate Input ───────────────────────────────────────────────────
    try:
        data = req.data
        if not isinstance(data, dict):
            raise ValueError("Request data must be a dictionary")

        base64_images = data.get("base64_images", [])
        if not base64_images or not isinstance(base64_images, list):
            raise ValueError(
                "Missing or invalid 'base64_images' array in request data"
            )

        commodity = data.get("commodity", "").strip()
        if not commodity:
            raise ValueError("Missing or empty 'commodity' field")

        questions_and_answers = data.get("questions_and_answers", [])
        if not isinstance(questions_and_answers, list):
            raise ValueError("'questions_and_answers' must be a list")

        language_code = data.get("language_code", "en")
        if language_code not in ("en", "ur"):
            language_code = "en"

    except (TypeError, KeyError) as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Invalid request data: {str(e)}",
        ) from e

    # ── Build Q&A Text ──────────────────────────────────────────────────
    qa_text = "\n\n".join(
        f"Q: {qa.get('question', '')}\nA: {qa.get('answer', '')}"
        for qa in questions_and_answers
    )

    # ── Build System Prompt ──────────────────────────────────────────────
    language_label = "Urdu (اردو)" if language_code == "ur" else "English"

    tier_descriptions_en = """1. **Excellent** – Premium export-grade. Uniform size/shape, vibrant natural colour, zero blemishes, no pest damage, firm texture, fresh aroma expected.
2. **Very Good** – High domestic-market grade. Minor cosmetic imperfections only (slight colour variation, tiny surface marks ≤5% area). No decay or pest evidence.
3. **Good** – Standard market-acceptable grade. Moderate cosmetic issues (colour unevenness, small bruises, slight wilting, minor shape irregularity). Still safe and nutritious.
4. **Satisfactory** – Below-average grade, acceptable for processing/value-addition only. Noticeable defects: partial discolouration, soft spots, early-stage shrivelling, minor insect traces.
5. **Unsatisfactory** – Rejected / unmarketable. Significant rot, mould, heavy pest infestation, foul odour indicators, structural collapse, or foreign-matter contamination."""

    tier_descriptions_ur = """1. **بہترین (Excellent)** – پریمیم برآمدی درجہ۔ یکساں سائز/شکل، روشن قدرتی رنگ، کوئی داغ نہیں، کوئی کیڑے نہیں، مضبوط ساخت، تازہ خوشبو۔
2. **بہت اچھا (Very Good)** – اعلیٰ گھریلو منڈی کا درجہ۔ صرف معمولی خوبصورتی کی خامیاں (تھوڑا رنگ کی تبدیلی، ریت کے نشانات ≤5%)۔ کوئی سڑن یا کیڑے کے سبوت نہیں۔
3. **اچھا (Good)** – معیاری منڈی قابل قبول درجہ۔ اعتدال پسند خوبصورتی کے مسائل (رنگ کی بے قاعدگی، چھوٹے چھلنے، معمولی کمزوری، معمولی شکل کی بے ترتیبی)۔ ابھی محفوظ اور غذائی۔
4. **مناسب (Satisfactory)** – اوسط سے نیچے کا درجہ، صرف پروسیسنگ/قدر اضافی کے لیے قابل قبول۔ نمایاں خامیاں: جزوی بے رنگی، نرم دھبے، ابتدائی مرحلہ سکڑنا، معمولی کیڑے کے نشانات۔
5. **ناقص (Unsatisfactory)** – مسترد / غیر فروخت شدہ۔ اہم سڑن، سفیدی، بھاری کیڑے، بدبو، ڈھانچے کا انہدام، یا غیر ملکی معاملات۔"""

    tier_descriptions = (
        tier_descriptions_ur if language_code == "ur" else tier_descriptions_en
    )

    system_prompt = f"""You are an expert post-harvest quality analyst for agricultural commodities.

RESPONSE LANGUAGE: {language_label}

CRITICAL RULE: You MUST ONLY process images of AGRICULTURAL COMMODITIES (fruits, vegetables, grains, pulses, spices, nuts, dry fruits, oilseeds, or other farm produce). If the image does NOT contain an agricultural commodity, respond with ONLY this JSON:
{{"error": "NOT_AGRICULTURAL", "message": "This image does not contain an agricultural commodity. Please upload an image of a fruit, vegetable, grain, pulse, spice, or other farm produce."}}

You have already analyzed the image(s) visually. Now you also have the user's answers to your follow-up questions. Use BOTH the image(s) AND the answers to make your FINAL quality classification.

Classify into EXACTLY ONE of these five tiers:

{tier_descriptions}

RULES:
• Use BOTH the visual evidence AND the user's answers for your assessment.
• When uncertain between two adjacent tiers, pick the LOWER tier.
• Output ONLY a valid JSON object — no markdown, no code fences.
• {'تمام جوابات، وجوہات اور اقدامات اردو میں ہوں۔' if language_code == 'ur' else 'All responses must be in the specified language.'}

Required JSON schema ({language_label}):
{{
  "tier": "<{'بہترین | بہت اچھا | اچھا | مناسب | ناقص' if language_code == 'ur' else 'Excellent | Very Good | Good | Satisfactory | Unsatisfactory'}>",
  "confidence": <float 0.0–1.0>,
  "commodity": "<commodity name>",
  "reasons": ["<reason 1>", "<reason 2>", ...],
  "corrective_actions": ["<action 1>", ...],
  "notes": "<optional string, max 200 chars, or empty string>"
}}"""

    # ── Build Content Parts (Text + Images) ───────────────────────────────
    image_count_text = (
        f"are {len(base64_images)} images of the same"
        if len(base64_images) > 1
        else "is the"
    )

    content_parts = [
        {
            "type": "text",
            "text": f"Here {image_count_text} commodity and the user's answers to the follow-up questions.\n\nCommodity: {commodity}\n\n{qa_text}\n\nNow give the FINAL 5-tier quality classification based on {'all images' if len(base64_images) > 1 else 'the image'} and these answers. Return ONLY valid JSON.",
        }
    ]

    for base64_image in base64_images:
        content_parts.append(
            {
                "type": "image_url",
                "image_url": {"url": base64_image},
            }
        )

    # ── Build Messages Array ─────────────────────────────────────────────
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": content_parts},
    ]

    # ── Call OpenRouter API ──────────────────────────────────────────────
    try:
        response_text = _call_openrouter_api(messages, max_tokens=512, temperature=0.1)
    except RuntimeError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"OpenRouter API error: {str(e)}",
        ) from e

    # ── Parse and Validate Response ──────────────────────────────────────
    try:
        parsed = _parse_json_from_response(response_text)
    except ValueError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to parse API response: {str(e)}",
        ) from e

    # ── Check for Non-Agricultural Image ─────────────────────────────────
    if parsed.get("error") == "NOT_AGRICULTURAL":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=parsed.get(
                "message",
                "This is not an agricultural commodity image.",
            ),
        )

    # ── Validate Required Fields ─────────────────────────────────────────
    if "tier" not in parsed:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message='Missing "tier" field in API response',
        )

    return parsed
