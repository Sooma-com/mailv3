## 1. Localization

- [x] 1.1 Add `download` label in en_US.inc and pt_PT.inc

## 2. PHP — Results Area

- [x] 2.1 In `render_searchresults()`: add a download button element, initially hidden

## 3. JavaScript

- [x] 3.1 Store response data in a variable on each search response
- [x] 3.2 Show download button when results are non-empty, hide when empty
- [x] 3.3 On download button click: build TXT content from stored data, create Blob, trigger download via temporary `<a>` element with timestamped filename
