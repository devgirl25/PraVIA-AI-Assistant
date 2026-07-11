import os
import json
from dotenv import load_dotenv
from groq import Groq


load_dotenv()

client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)


def parse_intent(user_text):

    prompt = f"""
You are PraVIA, a personal phone assistant.

Convert the user command into JSON.

Available intents:

OPEN_APP
MAKE_CALL
SEND_SMS
UNKNOWN


Examples:

Command:
Open Instagram

Output:
{{
"intent":"OPEN_APP",
"parameters":{{
"app":"Instagram"
}}
}}


Command:
Call Rahul

Output:
{{
"intent":"MAKE_CALL",
"parameters":{{
"contact":"Rahul"
}}
}}


Command:
Message Rahul saying I am late

Output:
{{
"intent":"SEND_SMS",
"parameters":{{
"contact":"Rahul",
"message":"I am late"
}}
}}


User command:

{user_text}


Return ONLY JSON.
"""


    response = client.chat.completions.create(

        model="llama-3.1-8b-instant",

        messages=[
            {
                "role":"user",
                "content":prompt
            }
        ],

        temperature=0
    )


    result=response.choices[0].message.content


    return json.loads(result)