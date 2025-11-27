import traceback
from app.core.config import settings
from collections import Counter
from openai import AsyncOpenAI
import os

# ----------------------------
# PRIMARY LLM: OpenAI
# ----------------------------
# Initialize OpenAI client
api_key = os.getenv("OPENAI_API_KEY")
if api_key and api_key.startswith("="):
    api_key = api_key.lstrip("=")

client = AsyncOpenAI(api_key=api_key)


# client = AsyncOpenAI(api_key=settings.openai_api_key)


class LLMClient:

    def __init__(self, model: str):
        self.model = model

    async def generate(self, prompt: str):
        """
        Primary LLM logic with automatic fallback.
        """
        try:
            # ========== PRIMARY: OPENAI ==========
            response = await client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
            )
            return response.choices[0].message.content

        except Exception as e:
            print("\n⚠️ OPENAI FAILED — FALLING BACK")
            traceback.print_exc()

            return self.fallback_generate(prompt)

    # ----------------------------
    # FALLBACK LLM LOGIC
    # ----------------------------
    def fallback_generate(self, prompt: str):
        """
        Rule-based fallback logic when LLM fails.
        Extracts top keywords + builds meaning.
        """

        # Cleanup prompt
        text = prompt.replace("Summarize this document:", "").replace("\n", " ")

        # Tokenization
        words = [w.lower() for w in text.split() if len(w) > 4]

        # Most frequent keywords
        freq = Counter(words)
        top_terms = [word for word, _ in freq.most_common(5)]

        # Construct crude summary
        summary = "Fallback summary:\n- Important keywords: " + ", ".join(top_terms[:4])

        # Construct recommendations
        recommendations = (
            "Fallback recommendations:\n"
            "1. Review document for high-risk keywords.\n"
            "2. Strengthen policy language around detected themes.\n"
            "3. Perform a compliance review manually for sensitive terms.\n"
        )

        # Decide output type by checking prompt
        if "recommendation" in prompt.lower():
            return recommendations

        return summary


async def get_llm_client():
    return LLMClient(model=settings.LLM_MODEL)
