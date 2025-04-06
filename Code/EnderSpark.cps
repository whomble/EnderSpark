/**
  Custom post processor for Wire EDM machine.

  Created by [Ton Nom ou Ton Projet]
  All rights reserved.

  $Revision: 1.0 $
  $Date: 2025-03-24 $

  FORKID {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
*/

description = "Custom Wire EDM";
vendor = "Almost completed projects";
legal = "Copyright (C) 2025 by [ender spark]";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "for ender 3 based wire edm.";


extension = "gcode";
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 0; // no arcs

// user-defined properties
properties = {
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "Use sequence numbers for each block of outputted code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "formats",
    type       : "integer",
    value      : 10,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "formats",
    type       : "integer",
    value      : 5,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  softwareVersion: {
    title      : "Software Version",
    description: "Specifies the WAM software version.",
    group      : "preferences",
    type       : "number",
    value      : 1.2,
    scope      : "post"
  },
  material: {
    title      : "Material",
    description: "Specifies the material to make use of the feed/speed database. Choose -Custom- to use Wire speed and Feedrate Properties.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"Stainless Steel", id:"StainlessSteel"},
      {title:"Steel", id:"Steel"},
      {title:"Aluminum", id:"Aluminum"},
      {title:"Copper", id:"Copper"},
      {title:"Brass", id:"Brass"},
      {title:"SMA Brass", id:"SMABrass"},
      {title:"Custom", id:"custom"}
    ],
    value: "Aluminum",
    scope: "post"
  },
  wireSpeedPerMM: {
    title      : "Wire Speed",
    description: "Specifies the wire speed if material type -Custom- is selected.",
    group      : "preferences",
    type       : "number",
    value      : 0,
    scope      : "post"
  },
  useFeeds: {
    title      : "Feedrate",
    description: "Specifies the feedrate if material type -Custom- is selected.",
    group      : "preferences",
    type       : "number",
    value      : 0,
    scope      : "post"
  }
};

var feedSpeedDatabase = [
  {id: "StainlessSteel", surfacespeed: 4.0, wireSpeedPerMM: 80.0},
  {id: "Steel", surfacespeed: 20.0, wireSpeedPerMM: 30.0},
  {id: "Aluminum", surfacespeed: 25.0, wireSpeedPerMM: 25.0},
  {id: "Copper", surfacespeed: 10.0, wireSpeedPerMM: 80.0},
  {id: "Brass", surfacespeed: 10.0, wireSpeedPerMM: 80.0},
  {id: "SMABrass", surfacespeed: 5.0, wireSpeedPerMM: 100.0},
];

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim:false});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim:false});

var xOutput = createVariable({prefix:"X", force:true}, xyzFormat);
var yOutput = createVariable({prefix:"Y", force:true}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({force:true}, gFormat); // modal group 1 // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-22

// collected state
var sequenceNumber;

/**
  Writes the specified block.
*/
function writeBlock() {
  if (getProperty("showSequenceNumbers")) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return ";" + String(text).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

var wireSpeedPerMM;
var tableFeedrate;
var materialThickness = undefined;
var quality = undefined;

function getMaterialThickness (section) {
  if (hasGlobalParameter("stock-lower-z") && hasGlobalParameter("stock-upper-z")) {
    materialThickness = xyzFormat.format(Math.abs(getGlobalParameter("stock-lower-z") - getGlobalParameter("stock-upper-z")));
  } else {
    error(localize("Stock is not defined into your setup."));
    return undefined;
  }
  return materialThickness;
}

function getCuttingData(section) {
  materialThickness = getMaterialThickness(section);

  if (getProperty("material") == "custom") {
    wireSpeed = getProperty("wireSpeed"); // Valeur personnalisée
    tableFeedrate = getProperty("useFeeds");
    quality = "Custom";
  } else {
    for (var c in feedSpeedDatabase) {
      if (feedSpeedDatabase[c].id == getProperty("material")) {
        wireSpeed = feedSpeedDatabase[c].wireSpeedPerMM * materialThickness;
        tableFeedrate = feedSpeedDatabase[c].surfacespeed / materialThickness;
        return;
      }
    }
  }
}

function getTableFeedrate(c, section) {
  switch (section.quality) {
  case 1: // fine
    tableFeedrate = feedSpeedDatabase[c].speedFineRate;
    quality = "Fine";
    break;
  case 2: // medium
    tableFeedrate = feedSpeedDatabase[c].speedFineRate + ((feedSpeedDatabase[c].speedRoughRate - feedSpeedDatabase[c].speedFineRate) / 2);
    quality = "Medium";
    break;
  case 3: // rough
    tableFeedrate = feedSpeedDatabase[c].speedRoughRate;
    quality = "Rough";
    break;
  default:
    // medium quality as default
    tableFeedrate = feedSpeedDatabase[c].speedFineRate + ((feedSpeedDatabase[c].speedRoughRate - feedSpeedDatabase[c].speedFineRate) / 2);
    quality = "Medium";
  }
  if (unit == MM) {
    tableFeedrate *= 1;
  }
  return tableFeedrate;
}

function onOpen() {
  if (getProperty("material") != "custom" && (getProperty("wireSpeedPerMM") != 0 || getProperty("useFeeds") != 0)) {
    writeComment("Warning: The properties -Wire speed and / or -Feedrate- are only used if the property -material- is set to -Custom-.");
  }
  getCuttingData(getSection(0));
  zOutput.disable();

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  /*
  if (programName) {
    writeComment(programName);
  }
*/
  if (programComment) {
    writeComment(programComment);
  }

  var cuttingTime = 0;
  var rapidTime = 0;
  var totalTime = 0;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var rapidFeedrate = (unit == MM ? 1905 : 75);
    var cuttingDistance = section.getCuttingDistance();
    var rapidDistance = section.getRapidDistance();
    cuttingTime += (cuttingDistance / tableFeedrate * 60);
    rapidTime += (rapidDistance / rapidFeedrate * 60);
  }
  totalTime = (cuttingTime + rapidTime);

  if (hasGlobalParameter("document-path")) {
    var documentPath = getGlobalParameter("document-path");
  }
  writeComment("-------------------------------Cut file parameters------------------------");
  writeComment("Input file name : " + documentPath);
  writeComment("Material name : " + getProperty("material"));
  writeComment("Material thickness : " + getMaterialThickness(getSection(0)) + (unit == MM ? "MM" : "IN"));
  writeComment("Cut Time: " + formatCycleTime(totalTime));
  writeComment("-------------------------------Do not modify the Gcode file---------------");

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": "  + description);
    }
  }

  // Relative coordinates and feed per min
  writeBlock("G90");
  writeBlock("G21");
  writeBlock("M83");

  var stock = getWorkpiece();
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
}

function onParameter(name, value) {
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  var abc = machineConfiguration.getABC(W);
  if (closestABC) {
    if (currentMachineABC) {
      abc = machineConfiguration.remapToABC(abc, currentMachineABC);
    } else {
      abc = machineConfiguration.getPreferredABC(abc);
    }
  } else {
    abc = machineConfiguration.getPreferredABC(abc);
  }

  try {
    abc = machineConfiguration.remapABC(abc);
    currentMachineABC = abc;
  } catch (e) {
    error(
      localize("Machine angles not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
    return new Vector();
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }

  return abc;
}

function formatCycleTime(cycleTime) {
  cycleTime += 0.5; // round up
  var seconds = cycleTime % 60 | 0;
  var minutes = ((cycleTime - seconds) / 60 | 0) % 60;
  var hours = (cycleTime - minutes * 60 - seconds) / (60 * 60) | 0;
  if (hours > 0) {
    return subst(localize("%1h:%2m:%3s"), hours, minutes, seconds);
  } else if (minutes > 0) {
    return subst(localize("%1m:%2s"), minutes, seconds);
  } else {
    return subst(localize("%1s"), seconds);
  }
}

function onSection() {
  getCuttingData(currentSection);
  writeln("");

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (hasParameter("operation:compensation")) {
    writeComment("Cut path : " + getParameter("operation:compensation"));
  }

  if (quality) {
    writeComment("Cut quality : " + quality);
  }

  switch (tool.type) {
  case TOOL_WATER_JET:
    break;
  default:
    error(localize("The CNC does not support the required tool/process. Only water jet cutting is supported."));
    return;
  }

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    break;
  case JET_MODE_ETCHING:
    error(localize("Etch cutting mode is not supported."));
    break;
  case JET_MODE_VAPORIZE:
    error(localize("Vaporize cutting mode is not supported."));
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  // var initialPosition = getFramePosition(currentSection.getInitialPosition());
  // writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "S" + secFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
  error(localize("Radius compensation is not supported."));
  return;
}

function onPower(power) {
  var startXYZ = getCurrentPosition(); // Position initiale (souvent X0 Y0 Z0)
  writeBlock("G92", "X" + startXYZ.x, "Y" + startXYZ.y, "E0"); // Redéfinir l'origine
  if (power) {
    writeBlock("M106", "S170");
    writeBlock("M106", "P1", "S255");
  } else {
    var endPauseScaleVariable = 0.15;
    writeln("");
  }
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  if (x || y) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y);
    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  // Déclaration de eOutput pour formater la commande extrudeur
  var eOutput = {
    format: function(val) {
      return val.toFixed(3); // ajuste le nombre de décimales si besoin
    }
  };

  if (pendingRadiusCompensation >= 0) {
    xOutput.reset();
    yOutput.reset();
  }
  var f = feedOutput.format(tableFeedrate ? tableFeedrate : feed);
  var maximumLineLength = toPreciseUnit(0.1, MM);
  var startXYZ = getCurrentPosition();
  var endXYZ = new Vector(_x, _y, _z);
  var length = Vector.diff(startXYZ, endXYZ).length;
   
  if (length > maximumLineLength) {
    var numberOfSegments = Math.max(Math.ceil(length / maximumLineLength), 1);
    var previousPoint = startXYZ;
    for (var i = 1; i <= numberOfSegments; ++i) {
      var p = Vector.lerp(startXYZ, endXYZ, i / numberOfSegments);
      var segX = xOutput.format(p.x);
      var segY = yOutput.format(p.y);
      var segDistance = Vector.diff(previousPoint, p).length;
      var extrusion = segDistance * wireSpeed
      // Combinaison des commandes XY et extrudeur sur la même ligne
      writeBlock(gMotionModal.format(1), f, segX, segY, "E" + eOutput.format(extrusion));
      previousPoint = p;
      setCurrentPosition(p);
    }
  } else {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    if (x || y) {
      var extrusion = length * wireSpeed;
      var block;
      if (pendingRadiusCompensation >= 0) {
        pendingRadiusCompensation = -1;
        switch (radiusCompensation) {
          case RADIUS_COMPENSATION_LEFT:
            block = [gMotionModal.format(1), gFormat.format(41), f, x, y];
            break;
          case RADIUS_COMPENSATION_RIGHT:
            block = [gMotionModal.format(1), gFormat.format(42), f, x, y];
            break;
          default:
            block = [gMotionModal.format(1), gFormat.format(40), f, x, y];
        }
      } else {
        block = [gMotionModal.format(1), f, x, y];
      }
      block.push("E" + eOutput.format(extrusion));
      writeBlock.apply(null, block);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  // Déclaration de eOutput pour formater l'extrusion
  var eOutput = {
    format: function(val) {
      return val.toFixed(3);
    }
  };
  // Coefficient d'extrusion en fonction du matériau (par défaut 1)
  var extrusionFactor = (typeof materialExtrusionFactor !== "undefined") ? materialExtrusionFactor : 1;

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }
  var start = getCurrentPosition();
  var arcLength = 0;
  
  // Pour la commande circulaire, on calcule l'arc parcouru en fonction du centre (cx,cy)
  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    // Calcul du rayon (distance entre start et centre)
    var radius = Math.sqrt(Math.pow(start.x - cx, 2) + Math.pow(start.y - cy, 2));
    arcLength = 2 * Math.PI * radius;
    switch (getCircularPlane()) {
      case PLANE_XY:
        writeBlock(
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          iOutput.format(cx - start.x, 0),
          jOutput.format(cy - start.y, 0),
          feedOutput.format(feed),
          "E" + eOutput.format(arcLength * feed * extrusionFactor)
        );
        break;
      default:
        linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
      case PLANE_XY:
        // Calcul du rayon et des angles pour l'arc partiel
        var radius = Math.sqrt(Math.pow(start.x - cx, 2) + Math.pow(start.y - cy, 2));
        var startAngle = Math.atan2(start.y - cy, start.x - cx);
        var endAngle = Math.atan2(y - cy, x - cx);
        var delta = endAngle - startAngle;
        if (clockwise) {
          if (delta > 0) delta = delta - 2 * Math.PI;
        } else { // sens anti-horaire
          if (delta < 0) delta = delta + 2 * Math.PI;
        }
        arcLength = Math.abs(delta) * radius;
        writeBlock(
          gMotionModal.format(clockwise ? 2 : 3),
          xOutput.format(x),
          yOutput.format(y),
          iOutput.format(cx - start.x, 0),
          jOutput.format(cy - start.y, 0),
          feedOutput.format(feed),
          "E" + eOutput.format(arcLength * feed * extrusionFactor)
        );
        break;
      default:
        linearize(tolerance);
    }
  }
}


var mapCommand = {
  COMMAND_STOP         : 0,
  COMMAND_OPTIONAL_STOP: 1
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  forceAny();
  feedOutput.reset();
}

function onClose() {
  writeBlock("M106", "S0");
  writeBlock("M106", "P1", "S0");
  writeBlock(mFormat.format(1404));
}

function setProperty(property, value) {
  properties[property].current = value;
}
