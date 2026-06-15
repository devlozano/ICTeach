const functions = require("firebase-functions");
const nodemailer = require("nodemailer");


// Gmail configuration
const transporter = nodemailer.createTransport({

  service: "gmail",

  auth: {

    user: "your.icteach.gmail@gmail.com",

    pass: "YOUR_GMAIL_APP_PASSWORD"

  }

});


// Send Teacher/Trainer credentials
exports.sendStaffPasswordEmail =
functions.https.onCall(async (data, context) => {


  const email = data.email;
  const name = data.name;
  const password = data.password;
  const role = data.role;



  if (!email || !password) {

    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing email or password"
    );

  }



  await transporter.sendMail({

    from:
      `"ICTeach Admin" <your.icteach.gmail@gmail.com>`,

    to:
      email,


    subject:
      "ICTeach Staff Account Created",



    html:

    `

    <h2>Welcome to ICTeach</h2>


    <p>Hello <b>${name}</b>,</p>


    <p>
    Your ${role} account has been created by the ICTeach administrator.
    </p>


    <p>
    Login Email:
    <b>${email}</b>
    </p>


    <p>
    Temporary Password:
    <b>${password}</b>
    </p>


    <p>
    Please change your password after your first login.
    </p>


    <br>


    <p>
    ICTeach Team
    </p>

    `

  });



  return {

    success: true

  };


});