# 📱 Medilocate
## 🚀 Overview  

Medilocate helps users track their medications, identify potential drug interactions, and schedule reminders based on prescribed dosages. Using **Apple VisionKit** for image-to-text extraction and integrating **Gemini AI** and the **FDA API**, the app provides real-time insights on medications, ensuring user safety and adherence to prescriptions.  

---

## 🛠 Features  

### 📌 **User Enrollment**  
- Users register with their **Date of Birth (DOB)**, **contraindications**, and **current medications**.  
- User data is managed using `UserModel.ts`.  

### 📸 **Medication Recognition**  
- Users take a **picture** of the medication box or pill before consumption.  
- **Apple VisionKit** extracts text from the image.  
- The **Gemini AI API** processes the extracted text into a structured JSON format, including:  
  - **Ingredients**  
  - **Brand name**  
  - **Generic name**  

### 🏥 **FDA API Integration**  
- The app fetches **metadata** on the scanned medication:  
  - ✅ **Side effects**  
  - 🔄 **Drug interactions**  
  - 💊 **Dosage directions**  
  - ⚠️ **Adverse reactions**  
  - 🚨 **Warnings**  

### 🗂 **Data Processing & Display**  
- The app formats retrieved information into a **structured JSON**.  
- If any **interactions** are found with the user's existing medications, an **alert** is triggered.  
- All details are displayed in an **intuitive UI** for easy comprehension.  

### ⏰ **Dosage Tracking & Reminders**  
- Users can tap **“Take Now”** to log the medication.  
- The app schedules reminders using **iCloud Calendar** based on **prescribed intervals**.  
- The **UserController** updates medication records.  

---

## 🏗 Tech Stack  

- **Swift** (iOS App)  
- **Apple VisionKit** (OCR)  
- **Google Gemini AI API** (Text Analysis)  
- **FDA API** (Drug Information)  
- **iCloud Calendar API** (Reminders)  

---

## 🔧 Installation  

1. **Clone the repository:**  
   ```sh
   git clone https://github.com/jbaek1/medilocatev2.git
   cd medilocatev2


