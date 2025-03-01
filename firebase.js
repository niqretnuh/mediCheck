// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDGXjlGqmva0KXEPV59yywrKE_hzBZeiFM",
  authDomain: "medilocatev2.firebaseapp.com",
  projectId: "medilocatev2",
  storageBucket: "medilocatev2.firebasestorage.app",
  messagingSenderId: "989669588433",
  appId: "1:989669588433:web:a218f07287998597bcf4f0",
  measurementId: "G-XQ860G6KNF"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);