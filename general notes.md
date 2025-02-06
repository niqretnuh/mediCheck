## API to Check Drug-Drug Interactions
https://dev.drugbank.com/guides/implementation/ddi_checker
## future idea
8. Early Detection of Cognitive Decline via Speech Patterns
	•	Unexplored Angle: Current Alzheimer’s and Parkinson’s detection models rely on clinical observations but not daily speech changes.
	•	Potential Project: Train an NLP model that analyzes long-term conversational changes (e.g., pauses, vocabulary loss, grammatical shifts) for early cognitive decline detection.
	•	Use Case: Enable proactive intervention for neurodegenerative diseases by monitoring patient speech in telehealth sessions.

https://open.fda.gov/apis/authentication/,

**new app flow:
**
- user enrols w DOB, contraindicatoins, medications currently being taken, (keep usermodel.ts)
- user takes a picture of medication box / pill that they're about to take
- **get chat to perform NER / image-to-text
	- extract .json of ingredients, brand name on box, generic name
- pass metadata of user prompted medication through FDA API**
	- side effects
	 -  interactions
	  -  directions (dosage)
	 - known adverse reactions
	  - any warnings
- get chat to format into a .json, we display this all to user intuitively, if any interactions found w existing medications, alert user
- have button where it says "take now" and add calendar events to user phone/icloud? based on calculated intervals of dosage, save medicine/or add to taking list (use userController to update)


| **Feature**                     | **Recommended Transformer Model / API**       |
|---------------------------------|----------------------------------------------|
| **OCR (Image-to-Text)**         | TrOCR, Donut, Google Vision OCR             |
| **NER (Medication & Ingredients)** | BioBERT, Med7 (SciSpacy), RxBERT            |
| **Drug Info (FDA API Processing)** | FDA OpenAPI + GPT-4 Turbo                   |
| **JSON Structuring**            | GPT-4 Function Calling, T5                  |
| **Calendar Scheduling**         | Google Calendar API, iCloud API             |


