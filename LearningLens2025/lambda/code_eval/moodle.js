import archiver from 'archiver';
import fetch from "node-fetch";
import path from "path";
import { PassThrough } from 'stream';

// Moodle configuration
const moodleUsername = process.env.MOODLE_USERNAME
const moodlePassword = process.env.MOODLE_PASSWORD
const MOODLE_URL = process.env.MOODLE_URL
const MOODLE_API = `${MOODLE_URL}/webservice/rest/server.php`;

// Logs into moodle and retrieves the authorization token
async function getAuthToken(){
    let params = new URLSearchParams({
      'username': moodleUsername,
      'password': moodlePassword,
      'service': 'moodle_mobile_app'
    })

    const res = await fetch(`${MOODLE_URL}/login/token.php?${params}`)

    const resJson = await res.json()

    const token = resJson.token
    return token
}

/**
 * Retrieves the submissions from moodle
 * @param {string} token 
 * @param {string|number} assignmentId Id of the assignment to download submissions for
 * @returns 
 */
async function getSubmissions(token, assignmentId) {
    const params = new URLSearchParams({
        wstoken: token,
        wsfunction: "mod_assign_get_submissions",
        moodlewsrestformat: "json",
        'assignmentids[0]': assignmentId.toString(),
    });

    const res = await fetch(`${MOODLE_API}?${params}`);
    const data = await res.json();
    console.log('data', data)
    
    if(!data.assignments || data.assignments.length === 0){
        return []
    }

    const assignment = data.assignments[0]
    return assignment.submissions || [];
}

/**
 * Get a JSON array with studentId and download links for a specific assignment
 */
async function getAssignmentSubmissions(token, assignmentId) {
    const submissions = await getSubmissions(token, assignmentId);
    console.log(submissions)
    const result = [];

    for (const submission of submissions) {
        const studentId = submission.userid;
        const files = [];

        // Loop through plugins and fileareas to find attached files
        for (const plugin of submission.plugins || []) {
        for (const filearea of plugin.fileareas || []) {
            for (const file of filearea.files || []) {
            files.push(`${file.fileurl}?token=${token}`);
            }
        }
        }

        if (files.length > 0) {
        result.push({ assignmentId, studentId, files });
        }
    }

    return result;
}

async function downloadFile(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to download ${url}`);

  const buffer = await res.arrayBuffer();
  return Buffer.from(buffer);
}


/**
 * Creates a zip file containing the submissions
 * @param {string|number} assignmentId 
 * @param {string} expectedOutput
 * @param {string | undefined} input
 * @returns An in-memory stream of the zip 
 */
export async function createSubmissionsZip(assignmentId, expectedOutput, input) {
  // 1. Get submissions from Moodle
    const token = await getAuthToken()
    const submissions = await getAssignmentSubmissions(token, assignmentId);
    const chunks = []
    // 2. Prepare zip archive
    const archive = archiver("zip", { zlib: { level: 9 } });
    const zipStream = new PassThrough();
    
    archive.pipe(zipStream);

    zipStream.on("data", chunk => chunks.push(chunk));

    let inputs = input.length > 0 ? input.split('\n') : []
    let outputs = expectedOutput
        .split("\n")
        .map(s => s.trim())
        .filter(s => s.length > 0)

    const inputOutputJson  = outputs.map((output, idx) => {
        const obj = { 'expectedOutput': output }
        
        if(inputs.length > 0){
            obj['input'] = inputs[idx]
        }

        return obj
    })

    archive.append(JSON.stringify(inputOutputJson), { name: 'expectedOutput' })

    // 3. Loop through each submission
    for (const submission of submissions) {
        const studentDir = `${submission.studentId}/`;

        // Add a file named "studentId" with the student's ID as content
        archive.append(String(submission.studentId), { name: path.join(studentDir, "studentId") });
        // Add a file named "assignmentId" with the assignment ID as content
        archive.append(String(submission.assignmentId), { name: path.join(studentDir, "assignmentId") });

        // Download each submission file and add to ZIP
        for (const fileUrl of submission.files) {
            const fileBuffer = await downloadFile(fileUrl);
            const filename = path.basename(new URL(fileUrl).pathname);
            archive.append(fileBuffer, { name: path.join(studentDir, filename) });
        }
    }

    // 4. Finalize the archive
    await archive.finalize();
    return Buffer.concat(chunks)
}