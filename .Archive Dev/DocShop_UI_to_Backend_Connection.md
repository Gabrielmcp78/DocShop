### 📡 DocShop – UI to Backend Connections Blueprint

This document outlines every known function, its purpose, and what UI element (button, field, tab, etc.) needs to be created and connected in the front end.

---

## 🧠 Core Features and Agents

### 1. `DocProcessingAgent.importFrom(urlString: String)`

**Purpose:** Scrapes documentation from a URL and stores it as `.md` file in the local library.

* **UI Representation:**

  * 📥 TextField: to enter a URL
  * 📤 Button: "Import into Library"
  * ✅ Success/Failure feedback view
  * 🔄 Agent status: show agent busy / idle indicator

### 2. `DocLibraryIndex.shared.documents`

**Purpose:** Holds metadata references for all documents in the library.

* **UI Representation:**

  * 📚 Sidebar list (ListView): of document titles
  * 🧾 Subtitle: source URL or parsed summary
  * 💡 Empty state: "No documents loaded."

### 3. `DocLibraryIndex.addDocument(_:)`

**Purpose:** Adds a document entry to the in-memory model (triggers UI update).

* **UI Representation:**

  * 🔄 Automatically called post-import
  * 🟢 Result should appear instantly in sidebar list

---

## 🪪 UI Components That Need Wiring

### A. `SidebarView`

* [x] Displays document list from `DocLibraryIndex`
* [x] URL entry field
* [x] Import button
* [ ] ⚠️ Needs: visual indicator of import progress

### B. `AgentInteractionView`

* [x] Static display of current agent logs
* [ ] Add: ability to show steps taken during import, and link to the file
* [ ] Add: send quick commands to the agent ("Retry last", "Scrape again")

### C. `SessionListView`

* [ ] Show list of previous session imports (timestamps, count, etc.)
* [ ] Action: re-import, delete, or rename imported data
* [ ] Add: breadcrumbs / history backrefs for re-annotating docs

### D. `DocumentDetailView (proposed)`

* [ ] Rich view of selected `.md` file (syntax highlighted)
* [ ] Actions: edit, tag, export, annotate, link to frameworks

---

## 🔌 Inter-agent Signals Needed

| Trigger          | Action                                           |
| ---------------- | ------------------------------------------------ |
| Import starts    | Notify AgentInteractionView to show "importing…" |
| Import finishes  | Update DocLibraryIndex, notify sidebar           |
| User selects doc | Open in detail view                              |
| Error occurs     | Log error and show toast or status bar           |

---

## 🚦 Navigation Infrastructure

A `NavigationView` with a `List` of tool modes:

* [x] Import Docs
* [x] Agent Interaction
* [x] Session Log
* [ ] (future) Doc Inspector / Detail View

---

## 🗂️ File & Folder Expectations

| File / Struct                | Folder  | Notes                                    |
| ---------------------------- | ------- | ---------------------------------------- |
| `SidebarView.swift`          | Views   | Hosts import and sidebar list            |
| `AgentInteractionView.swift` | Views   | Displays live feedback from agent        |
| `SessionListView.swift`      | Views   | Timeline of doc loads                    |
| `DocProcessingAgent.swift`   | Agents  | Singleton import handler                 |
| `DocLibraryIndex.swift`      | Data    | Observable doc metadata store            |
| `DocumentMetaData.swift`     | Models  | Metadata per doc                         |
| `DocStore.swift`             | Storage | File write/read/cleanup logic (optional) |

---

## 🌐 Support for JavaScript-Heavy Documentation Sites

### Why This Is Needed
Many modern documentation sites (including Apple’s developer docs) load their main content dynamically using JavaScript. The current DocShop agent only fetches the static HTML, so it misses content rendered after page load. To fully capture such docs, we need to use a headless browser to render the page and extract the final HTML.

### Solution Overview
- Use a headless browser (like Puppeteer or Playwright) to load the page, execute JavaScript, and extract the fully rendered HTML.
- Integrate this with DocShop by calling a Node.js script from Swift, passing the URL and receiving the rendered HTML.
- Continue using SwiftSoup and Markdown conversion on the returned HTML.

### Implementation Steps

#### 1. Node.js Script (Puppeteer Example)
Create a file called `rendered-html.js`:

```js
// rendered-html.js
const puppeteer = require('puppeteer');

(async () => {
  const url = process.argv[2];
  if (!url) {
    console.error('No URL provided');
    process.exit(1);
  }
  const browser = await puppeteer.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
  const html = await page.content();
  console.log(html);
  await browser.close();
})();
```

Install Puppeteer:
```sh
npm install puppeteer
```

#### 2. Swift Integration
In your `DocProcessingAgent`, add a method to call this script and get the rendered HTML:

```swift
func fetchRenderedHTML(urlString: String) async throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["node", "path/to/rendered-html.js", urlString]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let html = String(data: data, encoding: .utf8), process.terminationStatus == 0 else {
        throw ProcessingError.failedToFetchRenderedHTML
    }
    return html
}
```

Replace your existing HTML fetch in `importFrom(urlString:)` with a call to `fetchRenderedHTML`. Then continue parsing and converting as before.

#### 3. Error Handling and Fallback
- If the Node.js script fails, fall back to the standard URLSession fetch.
- Log errors and inform the user if both methods fail.

#### 4. Security Note
- Only run trusted scripts and sanitize input URLs.
- Consider sandboxing or restricting Node.js execution if distributing the app.

---

### User Experience
- Users can now import documentation from sites that require JavaScript to render content.
- The import process may take a few seconds longer for such sites.
- Errors are surfaced in the UI if the fetch fails.

---

### Next Steps
- Add a UI indicator for “rendering with headless browser” if desired.
- Optionally, allow users to choose between fast (static) and full (rendered) import modes.
- Test with a variety of documentation sites to ensure robust coverage.

---

Let me know when you're ready to scaffold the UI hooks, or if you'd like visual flowcharts generated for each connection!

🔁 Next: Build the app shell (`ContentView`) and make it all switchable and observable.
