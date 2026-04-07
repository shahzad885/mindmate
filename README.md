# 🧠 MindMate — AI Life Companion

MindMate is a Flutter app that acts as your closest AI friend — it **remembers everything you tell it** across conversations and uses that context to give deeply personal responses.

# Demo

<img width="820" height="587" alt="image" src="https://github.com/user-attachments/assets/7d0bee73-91fa-427a-b6d3-07650634ab44" />


## 💡 What Makes It Different

Most AI chat apps forget you the moment you close them. MindMate doesn't.

- Tell it your name → it remembers
- Mention your boss, your goals, your struggles → it remembers
- Close the app, come back a week later → it still knows your story

Every message you send is silently analyzed. People, emotions, goals and events are extracted and stored locally. Before every AI response, your full memory context is injected into the prompt so MindMate always responds like someone who truly knows you.

---


## 🔌 Tech Stack


| Framework | Flutter 3.41.1 |
| State | Riverpod |
| Storage | Hive (local, on-device) |
| AI | Gemini 2.5 Flash (swappable to Claude / GPT-4o) |


---

## 🚀 Setup

```bash
git clone https://github.com/yourusername/mindmate.git
cd mindmate
flutter pub get
```

Create `.env` in project root:
```
GEMINI_API_KEY=your_key_here
```


