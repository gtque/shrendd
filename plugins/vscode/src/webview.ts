// Declare acquireVsCodeApi for TypeScript to avoid "Cannot find name" error
declare function acquireVsCodeApi(): { postMessage: (msg: any) => void };

const vscode = acquireVsCodeApi();

window.addEventListener('DOMContentLoaded', () => {
  const source = document.getElementById('source') as HTMLDivElement;
  const processed = document.getElementById('processed') as HTMLPreElement;
  const shrenddStatus = document.getElementById('text-status') as HTMLInputElement;
  const checkForce = document.getElementById('check-force') as HTMLInputElement;
  const selectRender = document.getElementById('select-render') as HTMLSelectElement;
  let initialContent = (window as any).initialShrenddContent || '';  
  // Create an enhanced editor with line numbers
  source.innerHTML = `
    <div id="editor-container" style="
      display: flex;
      width: 100%;
      height: 100%;
      background: #1e1e1e;
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 14px;
      line-height: 1.5;
      overflow: hidden;
    ">
      <div id="line-numbers" style="
        background: #252526;
        color: #858585;
        padding: 16px 8px 16px 16px;
        text-align: right;
        user-select: none;
        border-right: 1px solid #3e3e42;
        min-width: 50px;
        overflow: hidden;
        white-space: nowrap;
      "></div>
      <div id="editor-wrapper" style="
        flex: 1;
        position: relative;
        overflow: hidden;
      ">
        <textarea 
          id="shrendd-editor" 
          style="
            width: 100%; 
            height: 100%; 
            border: none; 
            outline: none; 
            resize: none; 
            font-family: inherit;
            font-size: inherit;
            line-height: inherit;
            background: transparent; 
            color: #d4d4d4; 
            padding: 16px; 
            tab-size: 4;
            white-space: pre-wrap;
            overflow-wrap: break-word;
            box-sizing: border-box;
            overflow-y: auto;
            overflow-x: hidden;
          "
          spellcheck="false"
          placeholder="Enter your Shrendd template content here..."
        >${initialContent}</textarea>
      </div>
    </div>
  `;
  
  const editor = document.getElementById('shrendd-editor') as HTMLTextAreaElement;
  const lineNumbers = document.getElementById('line-numbers') as HTMLDivElement;
  const editorWrapper = document.getElementById('editor-wrapper') as HTMLDivElement;
  let suppressUpdate = false;

  // Function to update line numbers
  function updateLineNumbers() {
    const lines = editor.value.split('\n');
    const editorRect = editor.getBoundingClientRect();
    const lineHeight = parseInt(getComputedStyle(editor).lineHeight);
    const paddingTop = 16; // Match textarea padding
    
    let lineNumbersHtml = '';
    let visualLineNumber = 1;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const actualLineNumber = i + 1;
      
      // Calculate if this line wraps
      const tempDiv = document.createElement('div');
      tempDiv.style.font = getComputedStyle(editor).font;
      tempDiv.style.width = (editor.clientWidth - 32) + 'px'; // Account for padding
      tempDiv.style.whiteSpace = 'pre-wrap';
      tempDiv.style.wordBreak = 'break-word';
      tempDiv.style.position = 'absolute';
      tempDiv.style.visibility = 'hidden';
      tempDiv.textContent = line || ' '; // Handle empty lines
      document.body.appendChild(tempDiv);
      
      const wrappedHeight = tempDiv.offsetHeight;
      const wrappedLines = Math.max(1, Math.round(wrappedHeight / lineHeight));
      
      document.body.removeChild(tempDiv);
      
      // Add line number for the actual line
      lineNumbersHtml += `<div style="height: ${lineHeight}px; position: relative;">`;
      lineNumbersHtml += `<span style="color: #858585;">${actualLineNumber}</span>`;
      lineNumbersHtml += '</div>';
      
      // Add continuation indicators for wrapped lines
      for (let w = 1; w < wrappedLines; w++) {
        lineNumbersHtml += `<div style="height: ${lineHeight}px; position: relative;">`;
        lineNumbersHtml += `<span style="color: #858585; opacity: 0.5;">↳</span>`;
        lineNumbersHtml += '</div>';
      }
    }
    
    lineNumbers.innerHTML = lineNumbersHtml;
  }

  // Sync scrolling between textarea and line numbers
  function syncScroll() {
    lineNumbers.scrollTop = editor.scrollTop;
  }

  // Handle tab key for proper indentation
  editor.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      shrenddStatus.value = "template updated";
      e.preventDefault();
      const start = editor.selectionStart;
      const end = editor.selectionEnd;
      
      if (e.shiftKey) {
        // Shift+Tab: Remove indentation
        const lineStart = editor.value.lastIndexOf('\n', start - 1) + 1;
        const lineText = editor.value.substring(lineStart, start);
        if (lineText.startsWith('  ')) {
          editor.value = editor.value.substring(0, lineStart) + 
                        lineText.substring(2) + 
                        editor.value.substring(start);
          editor.setSelectionRange(start - 2, end - 2);
        }
      } else {
        // Tab: Add indentation (2 spaces)
        editor.value = editor.value.substring(0, start) + '  ' + editor.value.substring(end);
        editor.setSelectionRange(start + 2, start + 2);
      }
      
      updateLineNumbers();
      
      // Trigger change event
      if (!suppressUpdate) {
        suppressUpdate = true;
        vscode.postMessage({ type: 'edit', text: editor.value });
        setTimeout(() => { suppressUpdate = false; }, 100);
      }
    }
  });

  // Handle content changes
  editor.addEventListener('input', () => {
    updateLineNumbers();
    shrenddStatus.value = "template updated";
    if (!suppressUpdate) {
      suppressUpdate = true;
      vscode.postMessage({ type: 'edit', text: editor.value });
      setTimeout(() => { suppressUpdate = false; }, 100);
    }
  });

  // Handle scrolling
  editor.addEventListener('scroll', syncScroll);

  // Handle window resize
  window.addEventListener('resize', () => {
    setTimeout(updateLineNumbers, 100);
  });

  // Handle messages from extension
  window.addEventListener('message', event => {
    const message = event.data;
    if (message.type === 'update') {
      if (!suppressUpdate && editor.value !== message.text) {
        suppressUpdate = true;
        const scrollTop = editor.scrollTop;
        const selectionStart = editor.selectionStart;
        const selectionEnd = editor.selectionEnd;
        
        editor.value = message.text;
        updateLineNumbers();
        
        // Restore cursor position and scroll
        editor.setSelectionRange(selectionStart, selectionEnd);
        editor.scrollTop = scrollTop;
        syncScroll();
        
        setTimeout(() => { suppressUpdate = false; }, 100);
      }
    } else if (message.type === 'processed') {
      processed.textContent = message.text;
    } else if (message.type === 'set-status') {
      console.log(`updating shrendd status: ${message.text}`);
      shrenddStatus.value = message.text;
    } else if (message.type === 'set-force') {
      console.log(`updating force: ${message.text}`);
      checkForce.checked = message.text;
    } else if (message.type === 'set-render') {
      let selectoptions = selectRender.getElementsByTagName('option');
      for (const option of Array.from(selectoptions)) {
        if (option.value === message.text) {
          option.selected = true;
          break;
        }
      }
    } else if (message.type === 'update-render') {
      console.log(`updating render: ${message.text}`);
      const selectoptions = Array.from(selectRender.getElementsByTagName('option'));
      const possibleValues = message.text.split(',');
      let possibilities: string[] = [];
      for (let theConfig of possibleValues) {
        theConfig = theConfig.trim().trimStart().trimEnd();
        possibilities.push(theConfig);
        // let found = false;
        if (selectoptions.find(option => option.value === theConfig) === undefined) {
          //need to add option if not found
          let newOption = document.createElement('option');
          newOption.value = theConfig;
          newOption.text = theConfig;
          // newOption.selected = true;
          selectRender.appendChild(newOption);
        }
      }
      for (const option of selectoptions) {
          // option.selected = true;
          // break;
        // }
        if (possibilities.find(possibility => possibility === option.value) === undefined) {
          //need to remove option if not found
          console.log("not found, removing: " + option.value);
          if (option.value !== '!build!') {
            selectRender.removeChild(option);
          }
        }
      }
      // console.log(`updating render: ${message.text}`);
      // const options = selectRender.getElementsByTagName('option');
    }
  });

  // Tab functionality
  (document.getElementById('tab-source') as HTMLButtonElement).onclick = () => {
    source.style.display = 'block';
    processed.style.display = 'none';
    let processedBtn = document.getElementById('tab-processed');
    if (processedBtn) {
      processedBtn.classList.remove('selected');
    }
    let sourcedBtn = document.getElementById('tab-source');
    if (sourcedBtn){
      sourcedBtn.classList.add('selected');
    }
    setTimeout(() => {
      editor.focus();
      updateLineNumbers();
      syncScroll();
    }, 50);
  };
  
  (document.getElementById('tab-processed') as HTMLButtonElement).onclick = () => {
    source.style.display = 'none';
    processed.style.display = 'block';
    let processedBtn = document.getElementById('tab-processed');
    if (processedBtn) {
      processedBtn.classList.add('selected');
    }
    let sourcedBtn = document.getElementById('tab-source');
    if (sourcedBtn){
      sourcedBtn.classList.remove('selected');
    }
    shrenddStatus.textContent = "checking template state"
    vscode.postMessage({ type: 'process' });
  };

  checkForce.onclick = () => {
    const isChecked: boolean = checkForce.checked;
    vscode.postMessage({ type: `force-${isChecked}` });
  };

  selectRender.addEventListener('change', (e) => {
    const target = e.target as HTMLSelectElement | null;
    if (target) {
      vscode.postMessage({ type: 'selectRender', value: target.value });
    }
  });

  // Initialize line numbers and focus
  setTimeout(() => {
    updateLineNumbers();
    syncScroll();
    editor.focus();
    vscode.postMessage({ type: `refocus` });
  }, 100);

  console.log('Enhanced Shrendd editor with line numbers initialized successfully');
});