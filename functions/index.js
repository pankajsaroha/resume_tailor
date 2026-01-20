const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const Razorpay = require("razorpay");
const fetch = require("node-fetch");
const crypto = require("crypto");

admin.initializeApp();

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

exports.generateTailoredResumeAI = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    const { data, auth } = request;
    try {
      console.log("🔥 generateTailoredResumeAI called");
      console.log("generateTailoredResumeAI: data received", {
        hasResumeText: !!data?.resumeText,
        hasJobDescription: !!data?.jobDescription,
        hasRequestId: !!data?.requestId,
      });
      if (!auth) {
        throw new HttpsError("unauthenticated", "Auth required");
      }

      console.log("AUTH_UID", auth.uid);

      const { resumeText, jobDescription, requestId } = data || {};
      if (!resumeText || !jobDescription) {
        throw new HttpsError(
          "invalid-argument",
          "resumeText and jobDescription required",
          { errorCode: "INVALID_INPUT", message: "resumeText and jobDescription required" }
        );
      }
      console.log("generateTailoredResumeAI: validation passed");

      const prompt = `
You are a resume tailoring assistant. Given the resume text and job description,
return a JSON object with:
{
  "keywordMatch": number (0-100),
  "tailoredResume": {
    "name": string,
    "role": string,
    "sections": [
      { "title": string, "content": string }
    ]
  }
}

Resume:
${resumeText}

Job Description:
${jobDescription}
    `;

      console.log("generateTailoredResumeAI: prompt created");

      const openAiKey = OPENAI_API_KEY.value();
      console.log("generateTailoredResumeAI: key resolved", {
        hasKey: !!openAiKey,
      });
      if (!openAiKey) {
        throw new HttpsError(
          "failed-precondition",
          "OpenAI key missing",
          { errorCode: "OPENAI_KEY_MISSING", message: "OpenAI key missing" }
        );
      }

      console.log("generateTailoredResumeAI: OpenAI call started");
      const response = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${openAiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [{ role: "user", content: prompt }],
            temperature: 0.3,
            response_format: { type: "json_object" },
          }),
        }
      );

      const json = await response.json();
      console.log("generateTailoredResumeAI: OpenAI response received");

      const content = json?.choices?.[0]?.message?.content;
      if (!content) {
        throw new Error("AI response missing");
      }

      const parsed = JSON.parse(content);

      return {
        status: "ok",
        requestId,
        keywordMatch: parsed.keywordMatch ?? 0,
        tailoredResume: parsed.tailoredResume ?? {},
      };
    } catch (err) {
      console.error("FUNCTION_ERROR", err);
      throw err;
    }
  }
);

exports.createPaymentOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const { data, auth } = request;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    const { requestId, amount, currency } = data || {};
    if (!requestId || !amount || !currency) {
      throw new HttpsError(
        "invalid-argument",
        "requestId, amount, and currency are required"
      );
    }
    try {
      const razorpay = new Razorpay({
        key_id: RAZORPAY_KEY_ID.value(),
        key_secret: RAZORPAY_KEY_SECRET.value(),
      });

      const order = await razorpay.orders.create({
        amount,
        currency,
        receipt: `receipt_${requestId}`,
      });

      return {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        keyId: RAZORPAY_KEY_ID.value(),
      };
    } catch (err) {
      throw new HttpsError("internal", "Order creation failed");
    }
  }
);

exports.verifyPayment = onCall(
  { secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const { data, auth } = request;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    const { orderId, paymentId, signature, requestId } = data || {};
    if (!orderId || !paymentId || !signature || !requestId) {
      throw new HttpsError(
        "invalid-argument",
        "orderId, paymentId, signature, requestId are required"
      );
    }

    const body = `${orderId}|${paymentId}`;
    const expectedSignature = crypto
      .createHmac("sha256", RAZORPAY_KEY_SECRET.value())
      .update(body)
      .digest("hex");

    if (expectedSignature !== signature) {
      return { verified: false };
    }

    await admin
      .firestore()
      .collection("resumeRequests")
      .doc(requestId)
      .set(
        {
          paid: true,
          paymentId,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    return { verified: true };
  }
);
