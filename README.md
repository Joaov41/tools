# Writing Tools (iOS)
Port by Joaov41 of the theJayTea/WritingTools work

A lightweight iOS app built with SwiftUI that helps improve your writing using Gemini API. It supports rewriting text, summarizing, extracting key points, and more. It also includes a Share Extension so you can process text from other apps conveniently. Implemented Q&A.
This code has the Ui optimized for Iphone. There is another version optmized for the ipad layout. 

## Features

- **Multiple Writing Options**  
  Transform text in several ways:
  - *Proofread*: Correct grammar, spelling, punctuation  
  - *Rewrite*: Improve phrasing and readability  
  - *Friendly / Professional / Concise*: Adjust the style or tone  
  - *Summary / Key Points*: Summarize text or extract bullet points  
  - *Table*: Convert text into a Markdown table
  - Added the hability to send images and jut not text to the LLM

  ![image](https://github.com/user-attachments/assets/14513b62-9a6b-441e-8aeb-d3fc1ede6bc1)

  ![image](https://github.com/user-attachments/assets/6ff6cbc4-fa67-44d0-8eb4-fa11b0b938fe)
![image](https://github.com/user-attachments/assets/6a1d4335-4e4b-4d5b-bff8-10a86c9222e2)



- **Chat Conversation**  
  An AI-powered chat feature that lets you carry on a multi-turn conversation with the model.

- **Share Extension**  
  Share text from other apps (e.g., Safari, Notes, Mail) into “Writing Tools” via the iOS Share Sheet.

- **Onboarding & Settings**  
  Simple onboarding experience. Configure your own API key and preferred model under “Settings.”

- ** Added the hability to share to the app an URL, through share sheet directly. The app will extract the text from that URL and makes the content available for use with any of the app's option, summarize, key points, etc. 
