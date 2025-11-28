from textblob import TextBlob


def get_sentiment(text: str) -> dict[str, float | str]:
    if not text or not text.strip():
        return {"polarity": 0.0, "sentiment": "Neutral"}

    polarity = TextBlob(text).sentiment.polarity

    if polarity > 0.3:
        label = "Positive"
    elif polarity < -0.3:
        label = "Negative"
    else:
        label = "Neutral"

    return {"polarity": polarity, "sentiment": label}
