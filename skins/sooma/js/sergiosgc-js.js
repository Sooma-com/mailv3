"use strict";
(() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropSymbols = Object.getOwnPropertySymbols;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __propIsEnum = Object.prototype.propertyIsEnumerable;
  var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
  var __spreadValues = (a, b) => {
    for (var prop in b || (b = {}))
      if (__hasOwnProp.call(b, prop))
        __defNormalProp(a, prop, b[prop]);
    if (__getOwnPropSymbols)
      for (var prop of __getOwnPropSymbols(b)) {
        if (__propIsEnum.call(b, prop))
          __defNormalProp(a, prop, b[prop]);
      }
    return a;
  };
  var __async = (__this, __arguments, generator) => {
    return new Promise((resolve, reject) => {
      var fulfilled = (value) => {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      };
      var rejected = (value) => {
        try {
          step(generator.throw(value));
        } catch (e) {
          reject(e);
        }
      };
      var step = (x) => x.done ? resolve(x.value) : Promise.resolve(x.value).then(fulfilled, rejected);
      step((generator = generator.apply(__this, __arguments)).next());
    });
  };

  // src/sergiosgc/src/index.ts
  if (!globalThis.sergiosgc) globalThis.sergiosgc = {};

  // src/xpathresult-polyfill/src/index.ts
  if (!(Symbol.iterator in XPathResult.prototype)) XPathResult.prototype[Symbol.iterator] = function* () {
    switch (this.resultType) {
      case XPathResult.NUMBER_TYPE:
        yield this.numberValue;
        break;
      case XPathResult.STRING_TYPE:
        yield this.stringValue;
        break;
      case XPathResult.BOOLEAN_TYPE:
        yield this.booleanValue;
        break;
      case XPathResult.UNORDERED_NODE_ITERATOR_TYPE:
      case XPathResult.ORDERED_NODE_ITERATOR_TYPE:
        var node;
        while (node = this.iterateNext()) yield node;
        break;
      case XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE:
      case XPathResult.ORDERED_NODE_SNAPSHOT_TYPE:
        var i;
        for (i = 0; i < this.snapshotLength; i++) yield this.snapshotItem(i);
        break;
      case XPathResult.ANY_UNORDERED_NODE_TYPE:
      case XPathResult.FIRST_ORDERED_NODE_TYPE:
        yield this.singleNodeValue;
        break;
      default:
        console.error("Unable to iterate unknown XPathResult resultType: " + this.resultType);
        break;
    }
  };

  // src/jsonschema-form/src/classes/SelectLoader.ts
  var SelectLoader = class _SelectLoader {
    static setup() {
      if (document.readyState == "loading") {
        window.addEventListener("load", _SelectLoader.setup);
        return;
      }
      _SelectLoader.bind();
    }
    static bind() {
      Array.from(document.getElementsByTagName("SELECT")).map(
        (elm) => elm
      ).filter(
        function(elm) {
          if ("string" != typeof elm.dataset.updateCallback) return false;
          if ("string" != typeof elm.dataset.updateDependsOn) return false;
          return true;
        }
      ).map(_SelectLoader.bindElement);
    }
    static bindElement(elm) {
      let form = elm.form;
      JSON.parse(elm.dataset.updateDependsOn).map(
        (dep) => Array.from(form.elements).filter((formElement) => formElement.name == dep)
      ).reduce(
        (acc, arr) => acc.concat(arr),
        []
      ).map(function(dep) {
        if (dep.dataset.selectLoaderHandlersAdded) return null;
        dep.dataset.selectLoaderHandlersAdded = "true";
        let updateFunction = _SelectLoader.executeUpdate.bind(window, elm, dep);
        dep.addEventListener("input", updateFunction);
        return updateFunction;
      }).filter(
        (f) => f
      ).map(
        (f) => f()
      );
    }
    static executeUpdate(toUpdate, updateSource) {
      return __async(this, null, function* () {
        let url = toUpdate.dataset.updateCallback;
        let argumentRe = /%<([^>]*)>/;
        let match;
        if (updateSource.disabled) return;
        while (match = argumentRe.exec(url)) {
          if ("undefined" == typeof toUpdate.form[match[1]]) {
            console.error("Form contains no argument '" + match[1] + "' when assembling update URL '" + toUpdate.dataset.updateCallback + "'");
            return;
          }
          let value2 = Array.from(toUpdate.form.elements).filter((elm) => elm.name == match[1] && !elm.disabled)[0].value;
          url = url.replace(match[0], value2);
        }
        let response;
        try {
          response = yield fetch(url, { credentials: "same-origin" });
        } catch (error) {
          console.error("Error fetching data from '" + url + "': " + error);
          return;
        }
        if (response.status != 200) {
          console.error("Error fetching data from '" + url + "': Status code: " + response.status + " Status text: " + response.statusText);
          return;
        }
        let json = yield response.json();
        if ("undefined" == typeof toUpdate.dataset.updateLabel) {
          console.error("data-update-label property not set on ", toUpdate);
          return;
        }
        let label = toUpdate.dataset.updateLabel;
        if ("undefined" == typeof toUpdate.dataset.updateValue) {
          console.error("data-update-value property not set on ", toUpdate);
          return;
        }
        let value = toUpdate.dataset.updateValue;
        if (!("data" in json)) {
          console.error("Update callback result contains no 'data' field");
          return;
        }
        if (!("collection" in json["data"])) {
          console.error("Update callback result contains no 'data.collection' field");
          return;
        }
        let options = json["data"]["collection"].reduce(
          function(acc, val) {
            acc.push({ value: val[value], label: val[label] });
            return acc;
          },
          toUpdate.getAttribute("placeholder") ? [{ value: "", label: toUpdate.getAttribute("placeholder") }] : []
        );
        let currentValue = toUpdate.value;
        if (options.length && !options.reduce((acc, val) => val["value"] == currentValue ? true : acc, false)) currentValue = options[0]["value"];
        while (toUpdate.firstChild) toUpdate.removeChild(toUpdate.firstChild);
        options.map(function(o) {
          let option = toUpdate.appendChild(document.createElement("OPTION"));
          option.setAttribute("value", o["value"]);
          if (currentValue == o["value"]) option.setAttribute("selected", "selected");
          option.appendChild(document.createTextNode(o["label"]));
        });
      });
    }
  };

  // src/xpath-observer/src/index.ts
  var XPathObserver = class extends EventTarget {
    constructor(xPath, rootNode = null) {
      super();
      this.nodes = [];
      this.xPath = xPath;
      this.rootNode = rootNode != null ? rootNode : document;
      this.observer = new MutationObserver(this.handleDocumentMutated.bind(this));
      this.observer.observe(this.rootNode, { attributes: true, childList: true, subtree: true });
      if (document.readyState == "complete") this.handleDocumentMutatedNewNodes();
      else window.addEventListener("load", this.handleDocumentMutatedNewNodes.bind(this));
    }
    handleDocumentMutated(mutations, _observer) {
      let handleNewNodes = false;
      let handleDeletedNodes = false;
      for (var mutation of mutations) {
        handleNewNodes || (handleNewNodes = mutation.type == "attributes" || mutation.addedNodes.length > 0);
        handleDeletedNodes || (handleDeletedNodes = mutation.type == "attributes" || mutation.removedNodes.length > 0);
      }
      if (handleNewNodes) this.handleDocumentMutatedNewNodes();
      if (handleDeletedNodes) this.handleDocumentMutatedDeletedNodes();
    }
    handleDocumentMutatedNewNodes() {
      Array.from(document.evaluate(this.xPath, this.rootNode)).filter((n) => !this.nodes.includes(n)).forEach((n) => {
        this.nodes.push(n);
        this.dispatchEvent(new CustomEvent("xpathobserver.node.new", { "detail": { "target": n } }));
      });
    }
    handleDocumentMutatedDeletedNodes() {
      const matchingNodes = Array.from(document.evaluate(this.xPath, this.rootNode));
      const deletedNodes = this.nodes.filter((n) => !matchingNodes.includes(n));
      this.nodes = this.nodes.filter((n) => !deletedNodes.includes(n));
      deletedNodes.forEach((n) => {
        this.dispatchEvent(new CustomEvent("xpathobserver.node.deleted", { "detail": { "target": n } }));
      });
    }
  };
  globalThis.sergiosgc.XPathObserver = XPathObserver;

  // src/jsonschema-form/src/classes/FormWizard.ts
  var FormWizard = class _FormWizard {
    static setup() {
      const observer = new XPathObserver("//form[count(./fieldset[contains(@class, 'wizard-step')]) > 1]");
      observer.addEventListener("xpathobserver.node.new", _FormWizard.handleNewForm);
      observer.addEventListener("xpathobserver.node.deleted", _FormWizard.handleNewForm);
    }
    static focusFirstInput(fieldSets) {
      const activeFieldSet = fieldSets.find((fs) => window.getComputedStyle(fs).display != "none");
      if (!activeFieldSet) return;
      Array.from(document.evaluate(".//*[self::input or self::textarea]", activeFieldSet, null, XPathResult.FIRST_ORDERED_NODE_TYPE)).forEach((input) => input.focus());
    }
    static handleNewForm(ev) {
      const cev = ev;
      const form = cev.detail.target;
      const fieldSets = Array.from(document.evaluate("./fieldset", form)).filter((fs) => fs.classList.contains("wizard-step"));
      if (0 == fieldSets.length) return;
      Array.from(fieldSets[0].getElementsByClassName("wizard")).filter((n) => n instanceof HTMLInputElement).filter((input) => input.getAttribute("name") == "back").forEach((n) => n.remove());
      Array.from(fieldSets[fieldSets.length - 1].getElementsByClassName("wizard")).filter((n) => n instanceof HTMLInputElement).filter((input) => input.getAttribute("name") == "continue").forEach((n) => n.remove());
      Array.from(form.getElementsByClassName("wizard")).filter((n) => n instanceof HTMLInputElement).filter((input) => input.getAttribute("name") == "back").forEach((n) => n.addEventListener("click", _FormWizard.handleBackClick));
      Array.from(form.getElementsByClassName("wizard")).filter((n) => n instanceof HTMLInputElement).filter((input) => input.getAttribute("name") == "continue").forEach((n) => n.addEventListener("click", _FormWizard.handleForwardClick));
      const firstFieldError = document.evaluate(".//node()[contains(@class, 'error')]", form, null, XPathResult.FIRST_ORDERED_NODE_TYPE).singleNodeValue;
      if (firstFieldError) {
        const fieldSetToActivate = Array.from(document.evaluate(".//ancestor::fieldset", firstFieldError)).reverse().find((fs) => fs.classList.contains("wizard-step"));
        const visibleDisplay = window.getComputedStyle(fieldSets[0]).display;
        fieldSets[0].style.display = "none";
        fieldSetToActivate.style.display = visibleDisplay;
      }
      Array.from(document.evaluate(".//*[self::input]", form)).forEach((input) => input.addEventListener("keypress", _FormWizard.handleEnterSubmission));
      _FormWizard.focusFirstInput(fieldSets);
    }
    static handleEnterSubmission(ev) {
      if (ev.key != "Enter") return;
      ev.stopPropagation();
      ev.preventDefault();
      if (ev.target == null) return;
      Array.from(document.evaluate(".//ancestor::fieldset//input[@name = 'continue' or @type = 'submit']", ev.target)).forEach((button) => button.click());
    }
    static handleBackClick(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      if (ev.target == null) return;
      const currentFieldset = Array.from(document.evaluate(".//ancestor::fieldset", ev.target)).reverse().find((fs) => fs.classList.contains("wizard-step"));
      const form = Array.from(document.evaluate(".//ancestor::form", currentFieldset)).reverse()[0];
      const fieldSets = Array.from(document.evaluate("./fieldset", form)).filter((fs) => fs.classList.contains("wizard-step"));
      const visibleDisplay = window.getComputedStyle(currentFieldset).display;
      fieldSets[fieldSets.indexOf(currentFieldset) - 1].style.display = visibleDisplay;
      currentFieldset.style.display = "none";
      _FormWizard.focusFirstInput(fieldSets);
    }
    static handleForwardClick(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      if (ev.target == null) return;
      const currentFieldset = Array.from(document.evaluate(".//ancestor::fieldset", ev.target)).reverse().find((fs) => fs.classList.contains("wizard-step"));
      const form = Array.from(document.evaluate(".//ancestor::form", currentFieldset)).reverse()[0];
      const fieldSets = Array.from(document.evaluate("./fieldset", form)).filter((fs) => fs.classList.contains("wizard-step"));
      const visibleDisplay = window.getComputedStyle(currentFieldset).display;
      fieldSets[fieldSets.indexOf(currentFieldset) + 1].style.display = visibleDisplay;
      currentFieldset.style.display = "none";
      _FormWizard.focusFirstInput(fieldSets);
    }
  };

  // src/jsonschema-form/src/index.ts
  SelectLoader.setup();
  FormWizard.setup();

  // src/attribute-bind/src/index.ts
  var AttributeBind = class {
    constructor(args) {
      this.nodes = [];
      var _a, _b;
      this.sourceXpath = args.sourceXpath;
      this.targetXpath = args.targetXpath;
      this.sourceAttribute = args.sourceAttribute;
      this.targetAttribute = (_a = args.targetAttribute) != null ? _a : args.sourceAttribute;
      this.rootNode = (_b = args.rootNode) != null ? _b : document;
      this.observer = new MutationObserver(this.handleAttributeChange.bind(this));
      const liveAttachObserver = new MutationObserver(this.attachSubsequentObservers.bind(this));
      liveAttachObserver.observe(this.rootNode, { subtree: true, childList: true, attributes: false });
      if (document.readyState == "complete") this.attachInitialObservers();
      else window.addEventListener("load", this.attachInitialObservers.bind(this));
    }
    attachInitialObservers() {
      Array.from(document.evaluate(this.sourceXpath, this.rootNode)).forEach(this.attachObserver.bind(this));
    }
    attachSubsequentObservers(mutations, _observer) {
      const validTargets = Array.from(document.evaluate(this.sourceXpath, this.rootNode));
      mutations.map((mutation) => Array.from(mutation.addedNodes)).flat().filter((node) => !this.nodes.includes(node) && validTargets.includes(node)).map(this.attachObserver.bind(this));
      mutations.map((mutation) => Array.from(mutation.removedNodes)).flat().filter((node) => this.nodes.includes(node)).map((node) => {
        this.nodes = this.nodes.filter((n) => n != node);
      });
    }
    attachObserver(node) {
      if (this.nodes.includes(node)) return;
      this.nodes.push(node);
      this.observer.observe(node, { attributeFilter: [this.sourceAttribute] });
      const targets = Array.from(document.evaluate(this.targetXpath, this.rootNode));
      targets.filter((target) => {
        typeof target[this.targetAttribute] != "function";
      }).filter((target) => target.getAttribute(this.targetAttribute) != node.getAttribute(this.sourceAttribute)).forEach(
        (target) => target.setAttribute(this.targetAttribute, node.getAttribute(this.sourceAttribute))
      );
      targets.filter((target) => typeof target[this.targetAttribute] == "function").forEach((target) => target[this.targetAttribute](node.getAttribute(this.sourceAttribute)));
    }
    handleAttributeChange(mutations, _observer) {
      const targets = Array.from(document.evaluate(this.targetXpath, this.rootNode));
      mutations.filter((m) => m.attributeName != null).forEach(
        (mutation) => targets.filter((target) => typeof target[this.targetAttribute] != "function").filter((target) => target.getAttribute(this.targetAttribute) != mutation.target.getAttribute(this.sourceAttribute)).forEach(
          (target) => target.setAttribute(this.targetAttribute, mutation.target.getAttribute(this.sourceAttribute))
        )
      );
      mutations.filter((m) => m.attributeName != null).forEach(
        (mutation) => targets.filter((target) => typeof target[this.targetAttribute] == "function").forEach((target) => target[this.targetAttribute](mutation.target.getAttribute(this.sourceAttribute)))
      );
    }
  };
  globalThis.sergiosgc.AttributeBind = AttributeBind;

  // src/assign-to-element/src/index.ts
  function assignToElement(targetElement, mapping) {
    if (targetElement instanceof String || "string" == typeof targetElement) {
      const targetElements = globalThis.sergiosgc.queryElements(targetElement);
      targetElements.forEach((element) => assignToElement(element, mapping));
      return;
    }
    for (const [path, value] of Object.entries(mapping)) {
      if (path.substring(0, 6) == "css[]:" || path.substring(0, 8) == "xpath[]:") {
        const localPath = path.replace("[]", "");
        let referenceElementsByParent = [];
        Array.from(globalThis.sergiosgc.queryElements(localPath, targetElement)).forEach((elementToClone) => {
          for (let i = 0; i < referenceElementsByParent.length; i++) {
            if (referenceElementsByParent[i]["parent"] == elementToClone.parentElement) {
              referenceElementsByParent[i]["nodes"].push(elementToClone);
              return;
            }
          }
          referenceElementsByParent.push({ parent: elementToClone.parentElement, nodes: [elementToClone] });
        });
        referenceElementsByParent.forEach((referenceElement) => referenceElement.nodes.slice(1).forEach((duplicateElement) => duplicateElement.remove()));
        if (value.array.length == 0) {
          Array.from(globalThis.sergiosgc.queryElements(localPath, targetElement)).forEach((referenceElement) => {
            if ("undefined" == typeof referenceElement.sergiosgc) referenceElement.sergiosgc = {};
            if ("undefined" == typeof referenceElement.sergiosgc["visible-display"]) referenceElement.sergiosgc["visible-display"] = window.getComputedStyle(referenceElement).display;
          });
        } else {
          Array.from(globalThis.sergiosgc.queryElements(localPath, targetElement)).forEach((referenceElement) => {
            if ("undefined" != typeof referenceElement.sergiosgc && "undefined" != typeof referenceElement.sergiosgc["visible-display"]) referenceElement.style.display = referenceElement.sergiosgc["visible-display"];
            value.array.forEach((data) => {
              var _a;
              let hydratedMapping = {};
              for (const [mappingKey, mappingExpression] of Object.entries(value.mapping)) {
                if ("string" == typeof mappingExpression) {
                  hydratedMapping[mappingKey] = resolveMappingExpression(mappingExpression, data);
                } else {
                  hydratedMapping[mappingKey] = {
                    array: resolveMappingExpression(mappingExpression["array"], data),
                    mapping: mappingExpression["mapping"]
                  };
                }
              }
              let clonedElement = referenceElement.cloneNode(true);
              (_a = referenceElement.parentNode) == null ? void 0 : _a.insertBefore(clonedElement, referenceElement);
              assignToElement(clonedElement, hydratedMapping);
            });
            referenceElement.remove();
          });
        }
      } else {
        globalThis.sergiosgc.queryElements(path, targetElement).forEach((element) => {
          element.innerHTML = value;
        });
      }
    }
  }
  function resolveMappingExpression(expression, data) {
    if ("." != expression[0]) throw new Error("Mapping expression should start with a dot (.)");
    let [_ignore, currentIndex, remainder] = expression.match(/^\.([^.]*)(.*)/);
    if ("undefined" == typeof data[currentIndex]) return void 0;
    if ("undefined" == typeof remainder || remainder == "") return data[currentIndex];
    return resolveMappingExpression(remainder, data[currentIndex]);
  }
  globalThis.sergiosgc.assignToElement = assignToElement;

  // src/query-elements/src/index.ts
  function queryElements(path, rootNode = null) {
    if (rootNode == null) {
      rootNode = document.documentElement;
    }
    if (path.substring(0, 4) == "css:") return Array.from(rootNode.querySelectorAll(path.substring(4)));
    if (path.substring(0, 6) == "xpath:") return Array.from(document.evaluate(path.substring(6), rootNode));
    throw new Error("path must begin with either css: or xpath:");
  }
  globalThis.sergiosgc.queryElements = queryElements;
  globalThis.sergiosgc.queryElement = (expression, referenceNode = null) => {
    var _a;
    return (_a = queryElements(expression, referenceNode)[0]) != null ? _a : null;
  };
  Element.prototype.queryElements = function(expression) {
    return globalThis.sergiosgc.queryElements(expression, this);
  };
  Element.prototype.queryElement = function(expression) {
    return globalThis.sergiosgc.queryElement(expression, this);
  };

  // src/sprintf/src/index.ts
  function sprintf(format, ...args) {
    const namedArguments = args.length > 0 && "object" == typeof args[0] ? args[0] : {};
    const positionalArguments = args.length > 0 && "object" == typeof args[0] ? args.slice(1) : args;
    return parse_format(format).map((token) => token.format(namedArguments, positionalArguments)).join("");
  }
  var Counter = class {
    constructor() {
      this.current = -1;
    }
    increment() {
      this.current += 1;
      return this.current;
    }
  };
  var Literal = class {
    constructor(value) {
      this.value = value;
    }
    format(named, positional) {
      return this.value;
    }
  };
  var Conversion = class {
    constructor(regex_match, positionCounter) {
      var _a, _b, _c, _d;
      if (!regex_match.conversion_specifier) throw new Error("Missing conversion specifier");
      this.conversion_specifier = regex_match.conversion_specifier;
      this.order = regex_match.order && regex_match.order != "*" ? (_a = regex_match.order_name) != null ? _a : parseInt(regex_match.order) : positionCounter.increment();
      this.flags = regex_match.flags.split("");
      this.width = (_b = regex_match.width) != null ? _b : "0";
      if (this.width == "*") this.width = "" + positionCounter.increment() + "$";
      this.precision = (_c = regex_match.precision) != null ? _c : "0";
      if (this.precision == "*") this.precision = "" + positionCounter.increment() + "$";
      this.length_modifier = (_d = regex_match.length_modifier) != null ? _d : null;
      this.conversion_specifier = regex_match.conversion_specifier;
      if (this.conversion_specifier == "i") this.conversion_specifier = "d";
      if (this.conversion_specifier == "F") this.conversion_specifier = "f";
      if (this.conversion_specifier == "G") this.conversion_specifier = "f";
      if (this.conversion_specifier == "C") {
        this.conversion_specifier = "c";
        this.length_modifier = "l";
      }
      if (this.conversion_specifier == "S") {
        this.conversion_specifier = "s";
        this.length_modifier = "l";
      }
    }
    format(named, positional) {
      const width = this.width.includes("$") ? positional[parseInt(this.width)] : parseInt(this.width);
      const precision = this.precision.includes("$") ? positional[parseInt(this.precision)] : parseInt(this.precision);
      const value = "string" == typeof this.order ? named[this.order] : positional[this.order];
      switch (this.conversion_specifier) {
        case "d":
          return this.d(value, width, precision);
        case "o":
          return this.o(value, width, precision);
        case "u":
          return this.u(value, width, precision);
        case "x":
          return this.x(value, width, precision);
        case "X":
          return this.x(value, width, precision).toUpperCase();
        case "e":
          return this.e(value, width, precision);
        case "E":
          return this.e(value, width, precision).toUpperCase();
        case "f":
          return this.f(value, width, precision);
        case "g":
          return this.f(value, width, precision == 0 ? 1 : precision);
        case "c":
          return String.fromCharCode(value);
        case "s":
          return this.s(value, width, precision);
        case "%":
          return "%";
        default:
          throw new Error("Unknown conversion specifier %" + this.conversion_specifier);
      }
    }
    padValue(value, width, override_pad_character = null) {
      if (value.length >= width) return value;
      const pad_character = (override_pad_character != null ? override_pad_character : this.flags.includes("0") && !this.flags.includes("-")) ? "0" : " ";
      return this.flags.includes("-") || override_pad_character != null ? value.padEnd(width, pad_character) : value.padStart(width, pad_character);
    }
    d(value, width, precision) {
      return this.padValue("" + Math.round(parseInt(value)), width);
    }
    o(value, width, precision) {
      const int_val = Math.floor(Math.abs(value));
      let result = int_val.toString(8);
      if (this.flags.includes("#") && result[0] != "0") result = "0" + result;
      return this.padValue(result, width);
    }
    u(value, width, precision) {
      return this.d(Math.floor(Math.abs(value)), width, precision);
    }
    x(value, width, precision) {
      return ((this.flags.includes("#") ? "0x" : "") + this.padValue(Math.floor(Math.abs(value)).toString(16), this.flags.includes("#") ? Math.max(0, width - 2) : width)).replace(new RegExp("0x(?<spaces> +)"), "$<spaces>0x");
    }
    e(value, width, precision) {
      var _a, _b;
      let parts = (_a = value.toExponential().match(new RegExp("(?<sign>-)?(?<integer>\\d*)(?:\\.(?<decimal>\\d+))e(?<esign>[-+])(?<exponent>\\d+)"))) == null ? void 0 : _a.groups;
      if (parts == null) throw new Error("Unable to parse exponential");
      let integer = parts.integer;
      let decimal = precision == 0 ? "" : "." + this.padValue(parts.decimal, precision, "0").substring(0, precision);
      let exponent = sprintf("%02d", parseInt(parts.exponent));
      return this.padValue(((_b = parts.sign) != null ? _b : "") + integer + decimal + "e" + parts.esign + exponent, width);
    }
    f(value, width, precision) {
      return this.padValue(
        "" + Math.trunc(parseFloat(value)) + "." + this.padValue(("" + parseFloat(value) % 1).replace("0", "").replace(".", ""), precision, "0"),
        width
      );
    }
    s(value, width, precision) {
      return this.padValue(width == 0 ? value : ("" + value).substring(0, width), width);
    }
  };
  var format_regex = new RegExp("(?<token>(?<conversion>%(?<order>\\d+\\$|\\*|<(?<order_name>[a-zA-Z_]*)>)?(?<flags>[-#0 +'I]*)(?<width>\\d+\\$|\\d+|\\*)?(?:.(?<precision>\\d+\\$|\\d+|\\*))?(?<length_modifier>hh|h|ll|l|q|L|j|z|Z|t)?(?<conversion_specifier>[diouxXeEfFgGaAcsCSpnm%]))|(?<literal>[^%]+))", "sg");
  function parse_format(format) {
    const positionCounter = new Counter();
    return Array.from(format.matchAll(format_regex)).map((match) => match.groups ? match.groups.literal ? new Literal(match.groups.literal) : new Conversion(match.groups, positionCounter) : null).filter((token) => token != null);
  }
  globalThis.sergiosgc.sprintf = sprintf;

  // src/call-on-load/src/index.ts
  function callOnLoad(f) {
    if (document.readyState == "complete") {
      f();
    } else {
      window.addEventListener("load", f);
    }
  }
  globalThis.sergiosgc.callOnLoad = callOnLoad;

  // src/button-collapser/src/index.ts
  window.sergiosgc.callOnLoad(function() {
    var onclick = function(ev) {
      ev.preventDefault();
      if (ev.target.collapsibleActionsDropdownDiv) {
        ev.target.collapsibleActionsDropdownDiv.style.display = ev.target.collapsibleActionsDropdownDiv.style.display == "none" ? "block" : "none";
      } else {
        let buttons = window.sergiosgc.queryElements("xpath:following::a", ev.target);
        console.log(buttons);
        for (var i = 0; i < buttons.length && buttons[i].classList.contains("button") && !buttons[i].classList.contains("button-collapser"); i++) ;
        buttons.splice(i);
        var dropdownDiv = document.createElement("DIV");
        dropdownDiv.classList.add("button-collapser-dropdown");
        dropdownDiv.style.position = "absolute";
        dropdownDiv.style.top = "" + (ev.target.offsetTop + ev.target.getBoundingClientRect().height) + "px";
        dropdownDiv.style.left = "" + (ev.target.offsetLeft + ev.target.getBoundingClientRect().width - 30) + "px";
        buttons.map((button) => dropdownDiv.appendChild(button));
        ev.target.parentNode.insertBefore(dropdownDiv, ev.target);
        (function(f) {
          f();
          window.addEventListener("resize", f);
        })(function() {
          var absoluteCoords = { x: ev.target.offsetLeft, y: ev.target.offsetTop };
          for (var node = ev.target.offsetParent; node && "static" == getComputedStyle(node).position; node = node.offsetParent) {
            absoluteCoords.x += node.offsetLeft;
            absoluteCoords.y += node.offsetTop;
          }
          dropdownDiv.style.top = "" + (absoluteCoords.y + ev.target.getBoundingClientRect().height) + "px";
          dropdownDiv.style.left = "" + (absoluteCoords.x + ev.target.getBoundingClientRect().width - 40) + "px";
          if (((rect) => [[rect.left, rect.top], [rect.right, rect.top], [rect.right, rect.bottom], [rect.left, rect.bottom]].map((point) => point[0] >= 0 && point[0] <= window.innerWidth && point[1] >= 0 && point[1] <= window.innerHeight).reduce((acc, val) => acc || val, false))(ev.target.getBoundingClientRect())) {
            if (dropdownDiv.getBoundingClientRect().right > window.innerWidth) {
              dropdownDiv.style.removeProperty("left");
              dropdownDiv.style.right = "0";
            }
          }
        });
        ev.target.collapsibleActionsDropdownDiv = dropdownDiv;
      }
      Array.prototype.slice.call(document.getElementsByClassName("button-collapser")).filter((a) => a.collapsibleActionsDropdownDiv).filter((a) => a != ev.target).map((a) => a.collapsibleActionsDropdownDiv.style.display = "none");
    };
    globalThis.sergiosgc.queryElements("css:a.button-collapser").forEach((a) => a.addEventListener("click", onclick));
  });

  // src/localization/src/index.ts
  var localizationTable = {};
  function __fn(original) {
    if (localizationTable.hasOwnProperty(original)) return localizationTable[original];
    return original;
  }
  function loadLocalizationTable(uri) {
    if ("string" == typeof uri) {
      fetch(uri).then((response) => response.json()).then((json) => {
        localizationTable = __spreadValues(__spreadValues({}, loadLocalizationTable), json);
      });
    } else {
      localizationTable = __spreadValues(__spreadValues({}, loadLocalizationTable), uri);
    }
  }
  if ("undefined" == typeof globalThis.__) globalThis.__ = __fn;
  globalThis.sergiosgc.loadLocalizationTable = loadLocalizationTable;

  // src/delete-confirm/src/index.ts
  globalThis.sergiosgc.callOnLoad(function() {
    const onclick = function(ev) {
      let target = ev.target;
      while (target && !("delete" in target.classList)) target = target.parentNode;
      if (!target) target = ev.target;
      if ("skipconfirmation" in target.classList) return;
      if ("delete-confirm" in target.classList) return;
      window.setTimeout(function() {
        target.classList.remove("delete-confirm-waiting");
        target.classList.add("delete-confirm");
        target.textContent = __("Click again to confirm deletion");
        target.removeEventListener("click", onclick);
      }, 500);
      target.textContent = __("Please wait...");
      target.classList.add("delete-confirm-waiting");
      ev.preventDefault();
    };
    globalThis.sergiosgc.queryElements("css:a.delete").forEach((a) => a.addEventListener("click", onclick));
  });

  // src/drag-and-drop-helper/src/index.ts
  var DragAndDropHelper = class {
    constructor(rootElement, draggableSelector, droppableSelector, transferDataCallback, eventNameOrCallback, validDropTargetCallback, hoverClass, onDragClass) {
      if (typeof transferDataCallback == "undefined" || transferDataCallback == null) transferDataCallback = function() {
        return null;
      };
      if (typeof eventNameOrCallback == "undefined" || eventNameOrCallback == null) eventNameOrCallback = "draganddrop";
      if (typeof validDropTargetCallback == "undefined" || validDropTargetCallback == null) validDropTargetCallback = function() {
        return true;
      };
      if (typeof hoverClass == "undefined" || hoverClass == null) hoverClass = "drophover";
      if (typeof onDragClass == "undefined" || onDragClass == null) onDragClass = "draganddropactive";
      this.rootElement = rootElement;
      this.draggableSelector = draggableSelector;
      this.droppableSelector = droppableSelector;
      this.transferDataCallback = transferDataCallback;
      this.eventNameOrCallback = eventNameOrCallback;
      this.validDropTargetCallback = validDropTargetCallback;
      this.hoverClass = hoverClass;
      this.onDragClass = onDragClass;
      new sergiosgc.MutationEventAttacher(rootElement, draggableSelector, "drag", this.drag.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, draggableSelector, "dragstart", this.dragstart.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, draggableSelector, "dragend", this.dragend.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, droppableSelector, "dragover", this.dragover.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, droppableSelector, "dragenter", this.dragenter.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, droppableSelector, "dragleave", this.dragleave.bind(this));
      new sergiosgc.MutationEventAttacher(rootElement, droppableSelector, "drop", this.drop.bind(this));
    }
    normalizeTarget(target) {
      const valid = sergiosgc.queryElements(this.draggableSelector, this.rootElement).concat(sergiosgc.queryElements(this.droppableSelector, this.rootElement));
      let cursor = target;
      while (cursor && !valid.includes(cursor)) cursor = cursor.parentNode ? cursor.parentNode : null;
      return cursor;
    }
    dragover(ev) {
      if (ev.target == null) return;
      let target = this.normalizeTarget(ev.target);
      if (!target) return;
      if (this.validDropTargetCallback(target, ev)) ev.preventDefault();
    }
    dragenter(ev) {
      if (ev.target == null) return;
      let target = this.normalizeTarget(ev.target);
      if (!target) return;
      if (!this.validDropTargetCallback(target, ev)) return;
      target.classList.add(this.hoverClass);
    }
    dragleave(ev) {
      if (ev.target == null) return;
      let target = this.normalizeTarget(ev.target);
      if (!target) return;
      if (!this.validDropTargetCallback(target, ev)) return;
      target.classList.remove(this.hoverClass);
    }
    drop(ev) {
      var _a, _b, _c, _d;
      if (ev.target == null) return;
      let target = this.normalizeTarget(ev.target);
      if (!target) return;
      if (!this.validDropTargetCallback(target, ev)) return;
      target.classList.remove(this.hoverClass);
      if (typeof this.eventNameOrCallback == "string") {
        target.dispatchEvent(new CustomEvent(this.eventNameOrCallback, { bubbles: true, detail: JSON.parse((_b = (_a = ev.dataTransfer) == null ? void 0 : _a.getData("application/json")) != null ? _b : "") }));
      } else {
        const eventName = this.eventNameOrCallback(target, ev);
        if ("string" == typeof eventName) {
          if (eventName) target.dispatchEvent(new CustomEvent("eventName", { bubbles: true, detail: JSON.parse((_d = (_c = ev.dataTransfer) == null ? void 0 : _c.getData("application/json")) != null ? _d : "") }));
        } else {
          target.dispatchEvent(eventName);
        }
      }
      ev.preventDefault();
    }
    drag(ev) {
      if (ev.target == null) return;
    }
    dragstart(ev) {
      var _a;
      if (ev.target == null) return;
      this.rootElement.classList.add(this.onDragClass);
      (_a = ev.dataTransfer) == null ? void 0 : _a.setData("application/json", JSON.stringify(this.transferDataCallback(ev.target, ev)));
    }
    dragend(ev) {
      this.rootElement.classList.remove(this.onDragClass);
    }
  };
  globalThis.sergiosgc.DragAndDropHelper = DragAndDropHelper;

  // src/mutation-event-attacher/src/index.ts
  var MutationEventAttacher = class {
    constructor(rootNode, xpathOrSelector, eventName, handlerFunction) {
      this.targets = [];
      this.rootNode = rootNode;
      this.xpathOrSelector = xpathOrSelector;
      this.eventName = eventName;
      this.handlerFunction = handlerFunction;
      sergiosgc.callOnLoad(this.init.bind(this));
    }
    init() {
      this.targets = sergiosgc.queryElements(this.xpathOrSelector, this.rootNode);
      this.targets.forEach((target) => target.addEventListener(this.eventName, this.handlerFunction));
      const observer = new MutationObserver(this.mutationCallback.bind(this));
      observer.observe(this.rootNode, {
        childList: true,
        attributes: true,
        subtree: true
      });
    }
    mutationCallback() {
      let matchingNodes = sergiosgc.queryElements(this.xpathOrSelector, this.rootNode);
      let deletedTargets = this.targets.filter((target) => !matchingNodes.includes(target));
      let newTargets = matchingNodes.filter((target) => !this.targets.includes(target));
      deletedTargets.forEach((target) => target.removeEventListener(this.eventName, this.handlerFunction));
      newTargets.forEach((target) => target.addEventListener(this.eventName, this.handlerFunction));
      this.targets = this.targets.concat(newTargets).filter((target) => !deletedTargets.includes(target));
    }
  };
  globalThis.sergiosgc.MutationEventAttacher = MutationEventAttacher;

  // src/template-node/src/index.ts
  Element.prototype.templateNode = function(deep, assignments) {
    let result = this.cloneNode(deep);
    result.removeAttributeNS(null, "id");
    for (const [path, value] of Object.entries(assignments)) {
      let match;
      if (match = path.match(new RegExp("^xpath:(?<pre>.*)\\/@(?<attribute>[A-Za-z_][-A-Za-z0-9.]*)$"))) {
        if (!match.groups) throw new Error("Invalid expression: " + path);
        let pre = match.groups.pre;
        let attribute = match.groups.attribute;
        if (pre == "") pre = "/";
        if (value == null) {
          sergiosgc.queryElements("xpath:" + pre, result).forEach((elm) => elm.removeAttribute(attribute));
        } else if (typeof value == "object" && attribute == "class") {
          sergiosgc.queryElements("xpath:" + pre, result).forEach((elm) => Object.entries(value).forEach(([_key, classVal]) => elm.classList.add(classVal)));
        } else if (typeof value == "object" && attribute == "style") {
          sergiosgc.queryElements("xpath:" + pre, result).forEach((elm) => {
            for (const [styleKey, styleValue] of Object.entries(value)) elm.style.setProperty(styleKey, styleValue);
          });
        } else {
          sergiosgc.queryElements("xpath:" + pre, result).forEach((elm) => elm.setAttributeNS(null, attribute, value));
        }
        continue;
      }
      sergiosgc.queryElements(path, result).forEach((node) => {
        if (node.nodeType == Node.ELEMENT_NODE) {
          while (node.firstChild) node.removeChild(node.firstChild);
          if (typeof value == "string") {
            node.appendChild(document.createTextNode(value));
          } else if (value) node.appendChild(document.createTextNode(value.join("")));
        }
      });
    }
    return result;
  };

  // src/overlay-dialog/src/index.ts
  globalThis.sergiosgc.overlayDialog = function(url, eventNameOrFactory, eventDetail) {
    var _a;
    const div = (_a = sergiosgc.queryElement("xpath:/html/body", document.documentElement)) == null ? void 0 : _a.appendChild(document.createElement("DIV"));
    div.classList.add("overlay-dialog-overlay");
    const iframe = div.appendChild(document.createElement("IFRAME"));
    iframe.setAttribute("src", url);
    const closeDialog = function() {
      div.classList.remove("active");
      div.classList.add("inactive");
      window.setTimeout(() => {
        var _a2;
        return (_a2 = div.parentNode) == null ? void 0 : _a2.removeChild(div);
      }, 200);
    };
    div.addEventListener("click", (ev) => ev.target == div && closeDialog());
    iframe.addEventListener("load", function(ev) {
      var _a2, _b;
      if (ev.target == null) return;
      if ((_a2 = ev.target.contentDocument) == null ? void 0 : _a2.querySelector("body.dialog")) {
        ev.target.contentWindow.closeDialog = closeDialog;
        return;
      }
      let pre = (_b = ev.target.contentDocument) == null ? void 0 : _b.querySelector("body > pre");
      if (!pre) return;
      let json = JSON.parse(pre.firstChild.wholeText);
      const newEvent = typeof eventNameOrFactory == "string" ? new CustomEvent(eventNameOrFactory, { bubbles: true, detail: __spreadValues(__spreadValues({}, eventDetail), { dialogResponse: json }) }) : eventNameOrFactory(json, eventDetail);
      iframe.ownerDocument.dispatchEvent(newEvent);
      closeDialog();
    });
    div.classList.add("active");
  };

  // src/konami-code/src/index.ts
  (() => {
    let keys = ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight", "b", "a"];
    let nextKey = 0;
    document.addEventListener("keydown", function(ev) {
      if (ev.key == keys[nextKey]) nextKey++;
      else nextKey = 0;
      if (nextKey == keys.length) {
        nextKey = 0;
        document.dispatchEvent(new CustomEvent("konamicode"));
      }
    }, { capture: true, once: false, passive: true });
  })();

  // src/input-datetime-utc/src/index.ts
  var _InputDatetimeUtc = class _InputDatetimeUtc {
    constructor() {
      globalThis.sergiosgc.callOnLoad(this.onLoad.bind(this));
    }
    static singleton() {
      if (!_InputDatetimeUtc.instance) _InputDatetimeUtc.instance = new _InputDatetimeUtc();
      return _InputDatetimeUtc.instance;
    }
    static parseDate(input) {
      var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n;
      let match;
      if (match = input.match(new RegExp("\\w{3}, (?<day>\\d+) (?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (?<year>\\d+) (?<hour>\\d\\d):(?<minute>\\d\\d):(?<second>\\d\\d)(?:\\.\\d+)? (?<offset>[-+]?\\d+)"))) {
        let day = parseInt((_b = (_a = match.groups) == null ? void 0 : _a.day) != null ? _b : "");
        let month = 1 + ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"].indexOf((_d = (_c = match.groups) == null ? void 0 : _c.month) != null ? _d : "");
        let year = parseInt((_f = (_e = match.groups) == null ? void 0 : _e.year) != null ? _f : "");
        if (year < 100) year += 2e3;
        let hour = parseInt((_h = (_g = match.groups) == null ? void 0 : _g.hour) != null ? _h : "");
        let minute = parseInt((_j = (_i = match.groups) == null ? void 0 : _i.minute) != null ? _j : "");
        let second = parseInt((_l = (_k = match.groups) == null ? void 0 : _k.second) != null ? _l : "");
        let offset = parseInt((_n = (_m = match.groups) == null ? void 0 : _m.offset) != null ? _n : "");
        input = year.toString().padStart(4, "0") + "-" + month.toString().padStart(2, "0") + "-" + day.toString().padStart(2, "0") + "T" + hour.toString().padStart(2, "0") + ":" + minute.toString().padStart(2, "0") + ":" + second.toString().padStart(2, "0") + ".000" + (offset == 0 ? "Z" : offset.toString().padStart(2, "0") + ":00");
      }
      let unixTimestamp = Date.parse(input);
      if (Number.isNaN(unixTimestamp)) return null;
      return new Date(unixTimestamp);
    }
    static toUTCIso8601(d) {
      return d.toISOString();
    }
    static toLocalIso8601(d) {
      return d.getFullYear().toString() + "-" + (1 + d.getMonth()).toString().padStart(2, "0") + "-" + d.getDate().toString().padStart(2, "0") + "T" + d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0") + ":" + d.getSeconds().toString().padStart(2, "0") + (d.getMilliseconds() == 0 ? "" : "." + d.getMilliseconds().toString().padStart(3, "0"));
    }
    onLoad() {
      const targetInputs = globalThis.sergiosgc.queryElements("css:input[type='datetime-local']").map((input) => input);
      targetInputs.forEach((input) => {
        var _a;
        const valueAsDate = _InputDatetimeUtc.parseDate((_a = input.getAttribute("value")) != null ? _a : "");
        if (valueAsDate == null) return;
        input.setAttribute("value", _InputDatetimeUtc.inputDateFormatter(valueAsDate));
      });
      targetInputs.map((input) => input.form).filter((form) => form != null).forEach((form) => {
        form.addEventListener("formdata", this.convertInputValuesToUTC.bind(
          this,
          targetInputs.filter((input) => input.form == form)
        ));
      });
      globalThis.sergiosgc.queryElements("css:.datetime-utc").forEach((element) => {
        const valueAsDate = _InputDatetimeUtc.parseDate(element.innerText);
        if (valueAsDate == null) return;
        while (element.firstChild) element.removeChild(element.firstChild);
        element.append(document.createTextNode(_InputDatetimeUtc.elementDateFormatter(valueAsDate).replace("T", " ")));
      });
    }
    convertInputValuesToUTC(inputs, formData) {
      if (inputs.length == 0) return;
      const form = inputs[0].form;
      inputs.map((input) => [input.name.toString(), Date.parse(input.value)]).filter(([_name, timestamp]) => !Number.isNaN(timestamp)).forEach(([name, timestamp]) => {
        formData.formData.set(name, _InputDatetimeUtc.toUTCIso8601(new Date(timestamp)));
      });
    }
  };
  _InputDatetimeUtc.inputDateFormatter = _InputDatetimeUtc.toLocalIso8601;
  _InputDatetimeUtc.elementDateFormatter = _InputDatetimeUtc.toLocalIso8601;
  var InputDatetimeUtc = _InputDatetimeUtc;
  globalThis.sergiosgc.InputDatetimeUtc = InputDatetimeUtc;
  globalThis.sergiosgc.InputDatetimeUtc.singleton();

  // src/location-polyfill/src/index.ts
  Location.prototype.setSearchParams = function(params) {
    let currentURL = new URL(window.location);
    for (const [key, value] of Object.entries(params)) {
      if (value === "") {
        currentURL.searchParams.delete(key);
      } else {
        currentURL.searchParams.set(key, value);
      }
    }
    window.location = currentURL;
  };

  // src/index.ts
  (function() {
    const event = new Event("sergiosgc.modules_loaded");
    window.dispatchEvent(event);
  })();
})();
//# sourceMappingURL=sergiosgc-js.js.map
