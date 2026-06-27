class AppConstant {
  // adb reverse tcp:3000 tcp:3000

  // start backend
  // npm run start:dev

  // admin passs 9999999999 123456
  // backend/seed.js
  // after chnaging pass run on terminal : node seed.js

  // start admin
  // npx serve .

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    // defaultValue: 'http://localhost:3000/api',
    defaultValue: 'https://navratri-app-backend.onrender.com/api',
  );
}
