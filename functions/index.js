const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.tailorResume = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required.'
    );
  }

  const resumeText = typeof data?.resumeText === 'string' ? data.resumeText : '';
  const jobDescription =
    typeof data?.jobDescription === 'string' ? data.jobDescription : '';
  const requestId = data?.requestId ?? null;

  if (!resumeText.trim() || !jobDescription.trim()) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'resumeText and jobDescription are required.'
    );
  }

  // Mock AI response for now
  const tailoredResume = {
    name: 'John Doe',
    role: 'Senior Software Engineer',
    summary:
      'Results-driven engineer with 5+ years of experience building scalable mobile and web products.',
    sections: [
      {
        title: 'Professional Summary',
        content:
          'Skilled in Flutter, React, and Node.js with a focus on performance and clean architecture.',
      },
      {
        title: 'Experience',
        content:
          'Senior Software Engineer | Tech Corp\n2020 - Present\n• Led mobile app development\n• Optimized API performance\n• Mentored junior engineers',
      },
      {
        title: 'Skills',
        content:
          'Flutter, Dart, React, Node.js, TypeScript, AWS, Firebase, Git',
      },
    ],
  };

  return {
    requestId,
    keywordMatch: 82,
    tailoredResume,
  };
});
