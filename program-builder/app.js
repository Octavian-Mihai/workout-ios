const STORAGE_KEY = "program-builder:draft";
const MUSCLE_VIEW_KEY = "program-builder:muscle-view";
const DEFAULT_SETS = 3;
const DEFAULT_REPS = 8;
const CATEGORIES = ["Push", "Pull", "Legs", "Explosive", "Core"];
const EQUIPMENT = [
  { id: "barbell", title: "Barbell" },
  { id: "machine", title: "Machine" },
  { id: "kettlebell", title: "Kettlebell" },
  { id: "dumbbell", title: "Dumbbell" },
  { id: "bodyweight", title: "Bodyweight" },
];
const MUSCLES = [
  "Chest",
  "Lats",
  "Traps",
  "Front Delts",
  "Side Delts",
  "Rear Delts",
  "Biceps",
  "Triceps",
  "Forearms",
  "Quads",
  "Hamstrings",
  "Glutes",
  "Calves",
  "Adductors",
  "Core",
  "Lower Back",
];
const MUSCLE_REGIONS = {
  Chest: "Upper body",
  Lats: "Upper body",
  Traps: "Upper body",
  "Front Delts": "Upper body",
  "Side Delts": "Upper body",
  "Rear Delts": "Upper body",
  Biceps: "Arms",
  Triceps: "Arms",
  Forearms: "Arms",
  Quads: "Lower body",
  Hamstrings: "Lower body",
  Glutes: "Lower body",
  Calves: "Lower body",
  Adductors: "Lower body",
  Core: "Trunk",
  "Lower Back": "Trunk",
  Tibialis: "Lower body",
};
const MUSCLE_VIEW_OPTIONS = [
  { id: "upper-lower", label: "Upper / lower" },
  { id: "push-pull-legs", label: "Push / pull / legs" },
  { id: "antagonists", label: "Antagonists" },
];
const DEFAULT_MUSCLE_VIEW = "push-pull-legs";
const LOWER_BODY_MUSCLES = ["Quads", "Hamstrings", "Glutes", "Calves", "Adductors", "Tibialis"];
const UPPER_BODY_MUSCLES = [
  "Chest",
  "Lats",
  "Traps",
  "Front Delts",
  "Side Delts",
  "Rear Delts",
  "Biceps",
  "Triceps",
  "Forearms",
  "Core",
  "Lower Back",
];
const PUSH_MUSCLES = ["Chest", "Front Delts", "Side Delts", "Triceps"];
const PULL_MUSCLES = ["Lats", "Traps", "Rear Delts", "Biceps"];
const LEG_MUSCLES = ["Quads", "Hamstrings", "Glutes", "Calves", "Adductors", "Tibialis"];
const PPL_OTHER_MUSCLES = ["Core", "Forearms", "Lower Back"];
const ANTAGONIST_GROUPS = [
  {
    title: "Biceps / Triceps",
    sides: [
      { label: "Biceps", muscles: ["Biceps"] },
      { label: "Triceps", muscles: ["Triceps"] },
    ],
  },
  {
    title: "Chest / Lats + Traps",
    sides: [
      { label: "Chest", muscles: ["Chest"] },
      { label: "Lats + Traps", muscles: ["Lats", "Traps"], foldBack: true },
    ],
  },
  {
    title: "Delts",
    sides: [
      { label: "Front Delts", muscles: ["Front Delts"] },
      { label: "Side Delts", muscles: ["Side Delts"] },
      { label: "Rear Delts", muscles: ["Rear Delts"] },
    ],
  },
  {
    title: "Quads / Hamstrings",
    sides: [
      { label: "Quads", muscles: ["Quads"] },
      { label: "Hamstrings", muscles: ["Hamstrings"] },
    ],
  },
  {
    title: "Calves / Tibialis",
    sides: [
      { label: "Calves", muscles: ["Calves"] },
      { label: "Tibialis", muscles: ["Tibialis"] },
    ],
  },
  {
    title: "Other",
    sides: [
      { label: "Forearms", muscles: ["Forearms"] },
      { label: "Core", muscles: ["Core"] },
      { label: "Adductors", muscles: ["Adductors"] },
      { label: "Glutes", muscles: ["Glutes"] },
      { label: "Lower Back", muscles: ["Lower Back"] },
    ],
  },
];
const PATTERN_RANK = [
  "Vertical Pull",
  "Horizontal Pull",
  "Squat",
  "Lunge / Split",
  "Hinge",
  "Biceps",
  "Accessory",
  "Horizontal Push",
  "Chest Isolation",
  "Vertical Push",
  "Delt Isolation",
  "Triceps",
  "Knee Flexion",
  "Knee Extension",
  "Glute Isolation",
  "Other Isolation",
  "Snatch",
  "Clean",
  "Plyometric",
  "Anti-Extension",
  "Flexion",
  "Rotation",
  "Carry",
];

const els = {
  programName: document.getElementById("program-name"),
  dayList: document.getElementById("day-list"),
  dayCount: document.getElementById("day-count"),
  addDayBtn: document.getElementById("add-day-btn"),
  dayEmpty: document.getElementById("day-empty"),
  dayEditor: document.getElementById("day-editor"),
  dayName: document.getElementById("day-name"),
  addExerciseBtn: document.getElementById("add-exercise-btn"),
  exerciseList: document.getElementById("exercise-list"),
  exerciseEmpty: document.getElementById("exercise-empty"),
  exportBtn: document.getElementById("export-btn"),
  importBtn: document.getElementById("import-btn"),
  importFile: document.getElementById("import-file"),
  picker: document.getElementById("picker"),
  pickerClose: document.getElementById("picker-close"),
  pickerSearch: document.getElementById("picker-search"),
  pickerBody: document.getElementById("picker-body"),
  filterCategory: document.getElementById("filter-category"),
  filterEquipment: document.getElementById("filter-equipment"),
  filterMuscle: document.getElementById("filter-muscle"),
  toast: document.getElementById("toast"),
  overview: document.getElementById("overview"),
};

let catalog = [];
let byName = new Map();
let foldedBackMuscles = [];
let state = emptyState();
let selectedDayId = null;
let toastTimer = 0;
let muscleView = loadMuscleView();

function emptyState() {
  return {
    uuid: crypto.randomUUID(),
    name: "",
    createdAt: iso8601(),
    days: [],
  };
}

function iso8601(date = new Date()) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function sortValue(value) {
  if (Array.isArray(value)) return value.map(sortValue);
  if (value && typeof value === "object") {
    const out = {};
    for (const key of Object.keys(value).sort()) {
      out[key] = sortValue(value[key]);
    }
    return out;
  }
  return value;
}

function prettyJSON(value) {
  return `${JSON.stringify(sortValue(value), null, 2)}\n`;
}

function sanitizeFilename(name) {
  const sanitized = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return sanitized ? `program-${sanitized}.json` : "program.json";
}

function canExport() {
  return Boolean(state.name.trim()) && state.days.length > 0;
}

function inferEquipment(name) {
  const n = name.toLowerCase();
  if (n.includes("kettlebell") || n.includes("goblet")) return "kettlebell";
  if (n.includes("dumbbell")) return "dumbbell";
  if (
    n.includes("push-up") ||
    n.includes("push up") ||
    n.includes("pull-up") ||
    n.includes("pull up") ||
    n.includes("chin-up") ||
    n.includes("chin up") ||
    (n.includes("dip") && !n.includes("machine")) ||
    n.includes("plank") ||
    n.includes("bodyweight") ||
    n.includes("pistol") ||
    n.includes("ab wheel")
  ) {
    return "bodyweight";
  }
  if (
    n.includes("machine") ||
    n.includes("leg press") ||
    n.includes("leg extension") ||
    n.includes("leg curl") ||
    n.includes("calf raise") ||
    n.includes("functional trainer") ||
    n.includes("cable") ||
    n.includes("lat pulldown") ||
    n.includes("pulldown") ||
    n.includes("face pull") ||
    n.includes("pushdown") ||
    n.includes("smith")
  ) {
    return "machine";
  }
  if (
    n.includes("barbell") ||
    n.includes("deadlift") ||
    n.includes("ohp") ||
    n.includes("overhead press") ||
    n.includes("hip thrust") ||
    n.includes("bench") ||
    n.includes("skull crusher")
  ) {
    return "barbell";
  }
  if (
    n.includes("squat") &&
    !n.includes("split") &&
    !n.includes("hack") &&
    !n.includes("goblet") &&
    !n.includes("pistol")
  ) {
    return "barbell";
  }
  if (
    n.includes("lunge") ||
    n.includes("split squat") ||
    n.includes("curl") ||
    n.includes("raise") ||
    n.includes("fly")
  ) {
    return "dumbbell";
  }
  return "bodyweight";
}

function containsAny(n, needles) {
  return needles.some((needle) => n.includes(needle));
}

function inferPattern(name, category) {
  const n = name.toLowerCase();
  if (category === "Pull") {
    if (containsAny(n, ["wrist", "shrug", "face pull", "rear delt", "reverse pec", "upright"])) {
      return "Accessory";
    }
    if (containsAny(n, ["pulldown", "pull-up", "pull up", "chin-up", "chin up"])) return "Vertical Pull";
    if (n.includes("row")) return "Horizontal Pull";
    if (n.includes("deadlift")) return "Hinge";
    if (n.includes("curl")) return "Biceps";
    return "Accessory";
  }
  if (category === "Push") {
    if (containsAny(n, ["pushdown", "skull", "triceps"]) || (n.includes("close-grip") && n.includes("bench"))) {
      return "Triceps";
    }
    if (containsAny(n, ["fly", "pec deck"])) return "Chest Isolation";
    if (containsAny(n, ["lateral raise", "front raise"])) return "Delt Isolation";
    if (containsAny(n, ["overhead press", "shoulder press", "landmine press"])) return "Vertical Push";
    if (containsAny(n, ["bench", "dip", "push-up", "chest press"])) return "Horizontal Push";
    return "Horizontal Push";
  }
  if (category === "Legs") {
    if (containsAny(n, ["lunge", "split squat", "step-up", "bulgarian"])) return "Lunge / Split";
    if (
      containsAny(n, [
        "deadlift",
        "romanian",
        "good morning",
        "jefferson",
        "back extension",
        "reverse hyper",
        "hip thrust",
        "glute-ham",
      ])
    ) {
      return "Hinge";
    }
    if (containsAny(n, ["nordic", "leg curl"])) return "Knee Flexion";
    if (n.includes("leg extension")) return "Knee Extension";
    if (containsAny(n, ["kickback", "abduction"])) return "Glute Isolation";
    if (containsAny(n, ["adduction", "calf", "tibialis"])) return "Other Isolation";
    if (containsAny(n, ["squat", "leg press"])) return "Squat";
    return "Other Isolation";
  }
  if (category === "Explosive") {
    if (n.includes("snatch")) return "Snatch";
    if (n.includes("clean")) return "Clean";
    return "Plyometric";
  }
  if (containsAny(n, ["plank", "ab wheel"])) return "Anti-Extension";
  if (containsAny(n, ["woodchop", "rotation"])) return "Rotation";
  if (containsAny(n, ["walk", "carry"])) return "Carry";
  return "Flexion";
}

function displaySorted(items) {
  return [...items].sort((a, b) => {
    const ra = PATTERN_RANK.indexOf(inferPattern(a.name, a.category));
    const rb = PATTERN_RANK.indexOf(inferPattern(b.name, b.category));
    if (ra !== rb) return ra - rb;
    return a.name.localeCompare(b.name);
  });
}

function equipmentTitle(id) {
  return EQUIPMENT.find((item) => item.id === id)?.title ?? id;
}

function selectedDay() {
  return state.days.find((day) => day.uuid === selectedDayId) ?? null;
}

function persist() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function loadMuscleView() {
  try {
    const stored = localStorage.getItem(MUSCLE_VIEW_KEY);
    if (MUSCLE_VIEW_OPTIONS.some((option) => option.id === stored)) return stored;
  } catch {
    /* ignore quota / private-mode failures */
  }
  return DEFAULT_MUSCLE_VIEW;
}

function setMuscleView(view) {
  if (!MUSCLE_VIEW_OPTIONS.some((option) => option.id === view) || view === muscleView) return;
  muscleView = view;
  try {
    localStorage.setItem(MUSCLE_VIEW_KEY, view);
  } catch {
    /* ignore quota / private-mode failures */
  }
  renderOverview();
}

function restore() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (!parsed || !Array.isArray(parsed.days)) return;
    state = {
      uuid: parsed.uuid || crypto.randomUUID(),
      name: parsed.name || "",
      createdAt: parsed.createdAt || iso8601(),
      days: parsed.days.map((day, index) => ({
        uuid: day.uuid || crypto.randomUUID(),
        name: day.name || `Day ${index + 1}`,
        exercises: Array.isArray(day.exercises) ? day.exercises : [],
      })),
    };
    selectedDayId = state.days[0]?.uuid ?? null;
  } catch {
    state = emptyState();
  }
}

function showToast(message) {
  els.toast.textContent = message;
  els.toast.classList.remove("hidden");
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => els.toast.classList.add("hidden"), 2400);
}

function photoMarkup(exercise, large = false) {
  const inner = exercise?.image
    ? `<img class="thumb" src="images/exercises/${exercise.image}" alt="" />`
    : `<span class="placeholder">Photo coming soon</span>`;
  return `<div class="photo-box${large ? " large" : ""}">${inner}</div>`;
}

function escapeHTML(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function render() {
  els.programName.value = state.name;
  els.dayCount.textContent = String(state.days.length);
  els.exportBtn.disabled = !canExport();
  els.exportBtn.title = canExport()
    ? "Download ProgramTemplateFile JSON"
    : "Add a program name and at least one day to export";

  els.dayList.innerHTML = state.days
    .map(
      (day) => `
      <li class="day-row${day.uuid === selectedDayId ? " selected" : ""}" data-day-id="${day.uuid}" draggable="true">
        <span class="drag-handle" title="Drag to reorder" aria-hidden="true">⋮⋮</span>
        <button type="button" class="select-day">
          <strong>${escapeHTML(day.name || "Untitled day")}</strong>
          <div class="day-meta">${day.exercises.length} exercise${day.exercises.length === 1 ? "" : "s"}</div>
        </button>
        <span class="muted">${day.uuid === selectedDayId ? "Editing" : ""}</span>
        <button type="button" class="btn btn-danger delete-day" aria-label="Delete day">Delete</button>
      </li>`
    )
    .join("");

  const day = selectedDay();
  if (!day) {
    els.dayEmpty.classList.remove("hidden");
    els.dayEditor.classList.add("hidden");
    renderOverview();
    return;
  }

  els.dayEmpty.classList.add("hidden");
  els.dayEditor.classList.remove("hidden");
  els.dayName.value = day.name;
  els.exerciseEmpty.classList.toggle("hidden", day.exercises.length > 0);

  els.exerciseList.innerHTML = day.exercises
    .map((item, index) => {
      const catalogItem = byName.get(item.name.toLowerCase());
      return `
        <li class="exercise-row" data-index="${index}" draggable="true">
          <span class="drag-handle" title="Drag to reorder" aria-hidden="true">⋮⋮</span>
          ${photoMarkup(catalogItem)}
          <div class="exercise-copy">
            <h3>${escapeHTML(item.name)}</h3>
            <p>${escapeHTML(displayMuscles(item.primaryMuscles).join(" · ") || "—")}</p>
          </div>
          <div class="stepper" data-field="targetSets" data-index="${index}">
            <span class="label">Sets</span>
            <button type="button" data-delta="-1" aria-label="Fewer sets">−</button>
            <strong>${item.targetSets}</strong>
            <button type="button" data-delta="1" aria-label="More sets">+</button>
          </div>
          <button type="button" class="btn btn-danger remove-exercise" data-index="${index}">Remove</button>
        </li>`;
    })
    .join("");
  renderOverview();
}

function uniqueMuscles(names) {
  const seen = new Set();
  const result = [];
  for (const raw of names || []) {
    const name = String(raw).trim();
    if (!name || seen.has(name)) continue;
    seen.add(name);
    result.push(name);
  }
  return result;
}

function refreshFoldedBackMuscles() {
  const names = new Set();
  for (const item of catalog) {
    for (const muscle of [...(item.primary || []), ...(item.secondary || [])]) {
      if (muscle) names.add(muscle);
    }
  }
  foldedBackMuscles = [...names].filter(
    (name) => !MUSCLES.includes(name) && !LOWER_BODY_MUSCLES.includes(name)
  );
}

function isFoldedBackMuscle(name) {
  return foldedBackMuscles.includes(name);
}

function displayMuscles(names) {
  return uniqueMuscles(names).filter((name) => !isFoldedBackMuscle(name));
}

function regionName(muscle) {
  if (MUSCLE_REGIONS[muscle]) return MUSCLE_REGIONS[muscle];
  if (isFoldedBackMuscle(muscle)) return "Upper body";
  return "Other";
}

function trimmedNumber(value, decimals = 1) {
  const raw = (Number(value) || 0).toFixed(Math.max(decimals, 0));
  const [integer, fraction = ""] = raw.split(".");
  const trimmed = fraction.replace(/0+$/, "");
  return trimmed ? `${integer}.${trimmed}` : integer;
}

function listPhrase(items) {
  if (!items.length) return "";
  const lower = items.map((item) => item.toLowerCase());
  if (lower.length === 1) return lower[0];
  if (lower.length === 2) return `${lower[0]} and ${lower[1]}`;
  return `${lower.slice(0, -1).join(", ")}, and ${lower[lower.length - 1]}`;
}

function sortCredit(row, usingSets) {
  return usingSets ? row.setCredit : row.exerciseCredit;
}

function overviewInsights(rows, exerciseCount, plannedSets) {
  if (exerciseCount === 0) {
    return ["No exercises in this rotation yet. Add days and lifts to see the split."];
  }

  const notes = [];
  const usingSets = plannedSets > 0;
  const byNameMap = Object.fromEntries(rows.map((row) => [row.name, row]));

  function credit(muscles) {
    return muscles.reduce((sum, name) => {
      const row = byNameMap[name];
      return sum + (usingSets ? row?.setCredit ?? 0 : row?.exerciseCredit ?? 0);
    }, 0);
  }

  function regionCredit(region) {
    return rows
      .filter((row) => row.region === region)
      .reduce((sum, row) => sum + (usingSets ? row.setCredit : row.exerciseCredit), 0);
  }

  if (!usingSets) {
    notes.push("Target sets are still 0. Exercise counts are shown; set planned sets on each lift to see volume.");
  }

  const regionOrder = ["Upper body", "Arms", "Lower body", "Trunk"];
  const missing = regionOrder.filter((region) => regionCredit(region) === 0);
  const trained = regionOrder.filter((region) => regionCredit(region) > 0);

  for (const region of missing) {
    if (region === "Lower body") {
      notes.push("No lower-body credit — quads, glutes, and hamstrings never appear as primary or secondary.");
    } else if (region === "Upper body") {
      notes.push("No upper-body work — chest, back, and delts are absent from the rotation.");
    } else if (region === "Trunk") {
      notes.push("Trunk is neglected. Core and lower back have no credit, even as secondary on compounds.");
    } else if (region === "Arms" && trained.includes("Upper body")) {
      notes.push("No arm credit yet. Biceps and triceps aren’t tagged, even as secondary on presses or pulls.");
    }
  }

  const push = credit(PUSH_MUSCLES);
  const pull = credit([...PULL_MUSCLES, ...foldedBackMuscles]);
  if (push > 0 || pull > 0) {
    const heavier = Math.max(push, pull);
    const lighter = Math.min(push, pull);
    if (heavier > 0 && lighter < heavier * 0.6) {
      if (push > pull) {
        notes.push("Pressing outweighs pulling. Add rows or pulldowns so the back keeps up with chest and delts.");
      } else {
        notes.push("Pull volume is well ahead of pressing. The split leans toward rows and vertical pulls.");
      }
    }
  }

  const quads = credit(["Quads"]);
  const posterior = credit(["Hamstrings", "Glutes"]);
  if (quads > 0 || posterior > 0) {
    if (quads > posterior * 1.6) {
      notes.push("Quad-dominant lower body. Hinges are light next to squat patterns.");
    } else if (posterior > quads * 1.6) {
      notes.push("Hinge-heavy lower body. Quads are light compared with hamstrings and glutes.");
    }
  }

  const frontPress = credit(["Chest", "Front Delts"]);
  const rearSupport = credit(["Rear Delts", "Traps", ...foldedBackMuscles]);
  if (frontPress > 0 && rearSupport < frontPress * 0.45) {
    notes.push("Pressing is loaded relative to rear delts and traps. Rows or face pulls would even the shoulder.");
  }

  const visibleRows = rows.filter((row) => !isFoldedBackMuscle(row.name));
  if (visibleRows[0] && visibleRows.length >= 2) {
    const total = visibleRows.reduce((sum, row) => sum + sortCredit(row, usingSets), 0);
    const second = sortCredit(visibleRows[1], usingSets);
    const topValue = sortCredit(visibleRows[0], usingSets);
    if (total > 0 && topValue >= total * 0.32 && topValue >= second * 1.8) {
      const unit = usingSets ? "set credit" : "exercise credit";
      notes.push(`${visibleRows[0].name} dominates the split with the largest share of ${unit}.`);
    }
  }

  if (!notes.length) {
    if (trained.length >= 3) {
      notes.push(`Coverage spans ${listPhrase(trained)}. Push/pull and lower-body credit are in the same ballpark.`);
    } else if (trained.length === 2) {
      notes.push(`Work is concentrated in ${listPhrase(trained)}.`);
    } else if (trained[0]) {
      notes.push(`This rotation is all ${trained[0].toLowerCase()} — other regions never appear.`);
    }
  }

  return notes.slice(0, 4);
}

function buildOverviewSnapshot() {
  const exercises = state.days.flatMap((day) => day.exercises);
  const exerciseCredit = {};
  const setCredit = {};

  for (const exercise of exercises) {
    const primary = uniqueMuscles(exercise.primaryMuscles);
    const primarySet = new Set(primary);
    const secondary = uniqueMuscles(exercise.secondaryMuscles).filter((muscle) => !primarySet.has(muscle));
    const sets = Math.max(Number(exercise.targetSets) || 0, 0);
    for (const muscle of primary) {
      exerciseCredit[muscle] = (exerciseCredit[muscle] || 0) + 1;
      setCredit[muscle] = (setCredit[muscle] || 0) + sets;
    }
    for (const muscle of secondary) {
      exerciseCredit[muscle] = (exerciseCredit[muscle] || 0) + 0.5;
      setCredit[muscle] = (setCredit[muscle] || 0) + sets * 0.5;
    }
  }

  const names = new Set([...Object.keys(exerciseCredit), ...Object.keys(setCredit)]);
  const usingSets = exercises.some((item) => Number(item.targetSets) > 0);
  const plannedSets = exercises.reduce((sum, item) => sum + Math.max(Number(item.targetSets) || 0, 0), 0);
  const rows = [...names]
    .map((muscle) => ({
      name: muscle,
      region: regionName(muscle),
      exerciseCredit: exerciseCredit[muscle] || 0,
      setCredit: setCredit[muscle] || 0,
    }))
    .sort((lhs, rhs) => {
      const l = sortCredit(lhs, usingSets);
      const r = sortCredit(rhs, usingSets);
      if (l !== r) return r - l;
      return lhs.name.localeCompare(rhs.name);
    });

  return {
    programName: state.name.trim() || "Untitled program",
    dayCount: state.days.length,
    exerciseCount: exercises.length,
    plannedSets,
    rows,
    usesSetVolume: plannedSets > 0,
    insights: overviewInsights(rows, exercises.length, plannedSets),
  };
}

function volumeDetail(exerciseCredit, setCredit, usesSetVolume) {
  const exercises = trimmedNumber(exerciseCredit, 1);
  if (usesSetVolume) {
    return `${exercises} ex · ${trimmedNumber(setCredit, 1)} sets`;
  }
  return `${exercises} ex`;
}

function muscleLookup(rows) {
  const map = new Map(rows.map((row) => [row.name, row]));
  return (name) =>
    map.get(name) || {
      name,
      region: regionName(name),
      exerciseCredit: 0,
      setCredit: 0,
    };
}

function makeSide(lookup, label, names, usingSets, options = {}) {
  const itemNames = names.filter((name) => !isFoldedBackMuscle(name));
  const foldNames = options.foldBack ? foldedBackMuscles : [];
  const items = itemNames.map(lookup);
  const folded = foldNames.map(lookup);
  const exerciseCredit =
    items.reduce((sum, row) => sum + row.exerciseCredit, 0) +
    folded.reduce((sum, row) => sum + row.exerciseCredit, 0);
  const setCredit =
    items.reduce((sum, row) => sum + row.setCredit, 0) + folded.reduce((sum, row) => sum + row.setCredit, 0);
  return {
    label,
    names: itemNames,
    items,
    exerciseCredit,
    setCredit,
    value: usingSets ? setCredit : exerciseCredit,
  };
}

function markFoldedBackUsed(used) {
  for (const name of foldedBackMuscles) used.add(name);
}

function leftoverNames(rows, used) {
  return rows
    .filter((row) => !used.has(row.name) && (row.exerciseCredit > 0 || row.setCredit > 0))
    .map((row) => row.name);
}

function shareLabel(value, total) {
  if (total <= 0) return "0%";
  return `${Math.round((value / total) * 100)}%`;
}

function renderVolumeBar(value, max, tone = 0, align = "start") {
  const fraction = max > 0 ? Math.min(Math.max(value / max, 0), 1) : 0;
  const width = fraction > 0 ? Math.max(fraction, 0.04) * 100 : 0;
  const alignClass = align === "end" ? " bar-end" : "";
  return `<div class="volume-bar${alignClass}"><span class="volume-bar-fill tone-${tone % 4}" style="width:${width}%"></span></div>`;
}

function renderMuscleLines(items, usesSetVolume, hideZero) {
  const visible = hideZero ? items.filter((row) => sortCredit(row, usesSetVolume) > 0) : items;
  if (!visible.length) return "";
  const max = Math.max(...visible.map((row) => sortCredit(row, usesSetVolume)), 0.01);
  return visible
    .map((row) => {
      const value = sortCredit(row, usesSetVolume);
      return `<div class="muscle-row">
        <div class="muscle-row-head">
          <span>${escapeHTML(row.name)}</span>
          <span class="muted">${escapeHTML(volumeDetail(row.exerciseCredit, row.setCredit, usesSetVolume))}</span>
        </div>
        ${renderVolumeBar(value, max, 0)}
      </div>`;
    })
    .join("");
}

function renderSideSub(side, usesSetVolume) {
  if (side.items.length < 2 || side.items.length > 3) return "";
  return `<p class="compare-sub">${side.items
    .map((item) => `${escapeHTML(item.name)} ${escapeHTML(volumeDetail(item.exerciseCredit, item.setCredit, usesSetVolume))}`)
    .join(" · ")}</p>`;
}

function duelMeta(side, usesSetVolume) {
  const detail = volumeDetail(side.exerciseCredit, side.setCredit, usesSetVolume);
  return side.share ? `${detail} · ${side.share}` : detail;
}

function renderDuel(left, right, usesSetVolume) {
  const max = Math.max(left.value, right.value, 0.01);
  return `<div class="compare-duel">
    <div class="compare-duel-side">
      <span class="compare-duel-name">${escapeHTML(left.label)}</span>
      ${renderVolumeBar(left.value, max, 0, "end")}
      <span class="muted">${escapeHTML(duelMeta(left, usesSetVolume))}</span>
      ${renderSideSub(left, usesSetVolume)}
    </div>
    <span class="compare-duel-vs">vs</span>
    <div class="compare-duel-side is-right">
      <span class="compare-duel-name">${escapeHTML(right.label)}</span>
      ${renderVolumeBar(right.value, max, 1, "start")}
      <span class="muted">${escapeHTML(duelMeta(right, usesSetVolume))}</span>
      ${renderSideSub(right, usesSetVolume)}
    </div>
  </div>`;
}

function renderSideStack(sides, usesSetVolume) {
  const max = Math.max(...sides.map((side) => side.value), 0.01);
  return sides
    .map(
      (side, index) => `
      <div class="muscle-row">
        <div class="muscle-row-head">
          <span>${escapeHTML(side.label)}</span>
          <span class="muted">${escapeHTML(volumeDetail(side.exerciseCredit, side.setCredit, usesSetVolume))}</span>
        </div>
        ${renderVolumeBar(side.value, max, index)}
        ${renderSideSub(side, usesSetVolume)}
      </div>`
    )
    .join("");
}

function renderBucketCard(bucket, max, tone, usesSetVolume, hideZero) {
  const empty = bucket.value <= 0;
  return `<div class="compare-bucket${empty ? " is-empty" : ""}">
    <div class="compare-bucket-head">
      <span>${escapeHTML(bucket.label)}${bucket.share ? ` <em>${escapeHTML(bucket.share)}</em>` : ""}</span>
      <span class="muted">${escapeHTML(volumeDetail(bucket.exerciseCredit, bucket.setCredit, usesSetVolume))}</span>
    </div>
    ${renderVolumeBar(bucket.value, max, tone)}
    ${renderMuscleLines(bucket.items, usesSetVolume, hideZero)}
  </div>`;
}

function renderNamedBreakdown(title, side, usesSetVolume) {
  const lines = renderMuscleLines(side.items, usesSetVolume, true);
  return `<div class="compare-group">
    <div class="region-head">
      <span>${escapeHTML(title)}</span>
      <span class="muted">${escapeHTML(volumeDetail(side.exerciseCredit, side.setCredit, usesSetVolume))}</span>
    </div>
    ${lines || `<p class="overview-empty">No credit yet.</p>`}
  </div>`;
}

function renderUpperLowerView(rows, usesSetVolume) {
  const lookup = muscleLookup(rows);
  const used = new Set([...UPPER_BODY_MUSCLES, ...LOWER_BODY_MUSCLES]);
  markFoldedBackUsed(used);
  const extras = leftoverNames(rows, used);
  const extraLower = extras.filter((name) => regionName(name) === "Lower body");
  const extraUpper = extras.filter((name) => regionName(name) !== "Lower body");
  const upper = makeSide(lookup, "Upper", [...UPPER_BODY_MUSCLES, ...extraUpper], usesSetVolume, { foldBack: true });
  const lower = makeSide(lookup, "Lower", [...LOWER_BODY_MUSCLES, ...extraLower], usesSetVolume);
  const total = upper.value + lower.value;
  upper.share = shareLabel(upper.value, total);
  lower.share = shareLabel(lower.value, total);
  return `<div class="overview-card">
    ${renderDuel(upper, lower, usesSetVolume)}
    ${renderNamedBreakdown("Upper", upper, usesSetVolume)}
    ${renderNamedBreakdown("Lower", lower, usesSetVolume)}
  </div>`;
}

function renderPushPullLegsView(rows, usesSetVolume) {
  const lookup = muscleLookup(rows);
  const used = new Set([...PUSH_MUSCLES, ...PULL_MUSCLES, ...LEG_MUSCLES, ...PPL_OTHER_MUSCLES]);
  markFoldedBackUsed(used);
  const extra = leftoverNames(rows, used);
  const buckets = [
    makeSide(lookup, "Push", PUSH_MUSCLES, usesSetVolume),
    makeSide(lookup, "Pull", PULL_MUSCLES, usesSetVolume, { foldBack: true }),
    makeSide(lookup, "Legs", LEG_MUSCLES, usesSetVolume),
    { ...makeSide(lookup, "Other", [...PPL_OTHER_MUSCLES, ...extra], usesSetVolume), optional: true },
  ];
  const visible = buckets.filter((bucket) => !bucket.optional || bucket.value > 0);
  const total = visible.reduce((sum, bucket) => sum + bucket.value, 0);
  for (const bucket of visible) bucket.share = shareLabel(bucket.value, total);
  const max = Math.max(...visible.map((bucket) => bucket.value), 0.01);
  return `<div class="overview-card">${visible
    .map((bucket, index) => renderBucketCard(bucket, max, index, usesSetVolume, true))
    .join("")}</div>`;
}

function markUsed(used, names) {
  for (const name of names) used.add(name);
}

function renderAntagonistView(rows, usesSetVolume) {
  const lookup = muscleLookup(rows);
  const used = new Set();
  markFoldedBackUsed(used);
  const groups = ANTAGONIST_GROUPS.map((group) => {
    const sides = group.sides.map((side) => {
      markUsed(used, side.muscles);
      return makeSide(lookup, side.label, side.muscles, usesSetVolume, { foldBack: Boolean(side.foldBack) });
    });
    return { title: group.title, sides };
  });
  const extras = leftoverNames(rows, used);
  const other = groups.find((group) => group.title === "Other");
  if (other) {
    for (const name of extras) other.sides.push(makeSide(lookup, name, [name], usesSetVolume));
  }
  return `<div class="overview-card">${groups
    .map((group) => {
      const empty = group.sides.every((side) => side.value <= 0);
      const pair = group.sides.length === 2;
      const body = pair ? renderDuel(group.sides[0], group.sides[1], usesSetVolume) : renderSideStack(group.sides, usesSetVolume);
      return `<div class="compare-group${empty ? " is-empty" : ""}">
        <div class="region-head"><span>${escapeHTML(group.title)}</span></div>
        ${body}
      </div>`;
    })
    .join("")}</div>`;
}

function renderMuscleView(snapshot) {
  const switcher = `<div class="view-switcher" role="tablist" aria-label="Muscle comparison view">${MUSCLE_VIEW_OPTIONS.map((option) => {
    const selected = option.id === muscleView;
    return `<button type="button" role="tab" class="view-chip${selected ? " selected" : ""}" data-muscle-view="${option.id}" aria-selected="${selected}">${escapeHTML(option.label)}</button>`;
  }).join("")}</div>`;

  let body;
  if (!snapshot.rows.length) {
    body = `<div class="overview-card"><p class="overview-empty">Add exercises to see how the split loads each muscle.</p></div>`;
  } else if (muscleView === "upper-lower") {
    body = renderUpperLowerView(snapshot.rows, snapshot.usesSetVolume);
  } else if (muscleView === "antagonists") {
    body = renderAntagonistView(snapshot.rows, snapshot.usesSetVolume);
  } else {
    body = renderPushPullLegsView(snapshot.rows, snapshot.usesSetVolume);
  }

  return `${switcher}${body}`;
}

function renderOverview() {
  const pane = els.overview.closest(".pane-overview");
  const scrollTop = pane?.scrollTop ?? 0;
  const snapshot = buildOverviewSnapshot();
  const dayWord = snapshot.dayCount === 1 ? "day" : "days";
  const insightIcon = `<svg class="insight-icon" width="16" height="16" viewBox="0 0 16 16" aria-hidden="true"><path fill="currentColor" d="M3.2 2.5h9.6c.7 0 1.2.5 1.2 1.2v6.2c0 .7-.5 1.2-1.2 1.2H8.4L5 13.8V11.1H3.2c-.7 0-1.2-.5-1.2-1.2V3.7c0-.7.5-1.2 1.2-1.2Z"/></svg>`;
  const insights = snapshot.insights.length
    ? `<div class="overview-block">
        <h3>Insight</h3>
        <div class="overview-card">
          ${snapshot.insights
            .map((note) => `<div class="insight-row">${insightIcon}<p>${escapeHTML(note)}</p></div>`)
            .join("")}
        </div>
      </div>`
    : "";

  els.overview.innerHTML = `
    <h2 class="overview-kicker">Program overview</h2>
    <p class="overview-title">${escapeHTML(snapshot.programName)}</p>
    <p class="overview-subtitle">${snapshot.dayCount} ${dayWord} in the rotation</p>
    <div class="overview-stats">
      <div class="overview-stat"><strong>${snapshot.dayCount}</strong><span>Days</span></div>
      <div class="overview-stat"><strong>${snapshot.exerciseCount}</strong><span>Exercises</span></div>
      <div class="overview-stat"><strong>${snapshot.plannedSets}</strong><span>Sets</span></div>
    </div>
    <p class="overview-caption">Primary muscles get full exercise and set credit. Secondary muscles get half, matching Anatomy 101 volume. Totals count each lift once; per-muscle numbers can add up to more because compounds credit more than one muscle.</p>
    ${insights}
    <div class="overview-block">
      <h3>By muscle</h3>
      ${renderMuscleView(snapshot)}
    </div>`;
  if (pane) pane.scrollTop = scrollTop;
}

function bindListDrag(list, onDrop) {
  let dragEl = null;
  list.addEventListener("mousedown", (event) => {
    const row = event.target.closest("li");
    if (!row || !list.contains(row)) return;
    row.draggable = Boolean(event.target.closest(".drag-handle"));
  });
  list.addEventListener("dragstart", (event) => {
    const row = event.target.closest("li");
    if (!row || !list.contains(row) || !row.draggable) return;
    dragEl = row;
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", "reorder");
    row.style.opacity = "0.55";
  });
  list.addEventListener("dragend", () => {
    if (dragEl) dragEl.style.opacity = "";
    dragEl = null;
    for (const row of list.children) row.draggable = false;
    onDrop([...list.children]);
  });
  list.addEventListener("dragover", (event) => {
    if (!dragEl) return;
    event.preventDefault();
    const row = event.target.closest("li");
    if (!row || row === dragEl || !list.contains(row)) return;
    const rect = row.getBoundingClientRect();
    const after = event.clientY > rect.top + rect.height / 2;
    list.insertBefore(dragEl, after ? row.nextSibling : row);
  });
}

function addDay() {
  const day = {
    uuid: crypto.randomUUID(),
    name: `Day ${state.days.length + 1}`,
    exercises: [],
  };
  state.days.push(day);
  selectedDayId = day.uuid;
  persist();
  render();
}

function deleteDay(id) {
  const day = state.days.find((item) => item.uuid === id);
  if (!day) return;
  if (day.exercises.length && !window.confirm(`Delete ${day.name || "this day"} and its exercises?`)) return;
  const index = state.days.findIndex((item) => item.uuid === id);
  state.days.splice(index, 1);
  if (selectedDayId === id) {
    selectedDayId = state.days[Math.max(0, index - 1)]?.uuid ?? null;
  }
  persist();
  render();
}

function addCatalogExercise(exercise) {
  const day = selectedDay();
  if (!day) return;
  day.exercises.push({
    catalogId: exercise.id,
    name: exercise.name,
    primaryMuscles: [...exercise.primary],
    secondaryMuscles: [...exercise.secondary],
    targetSets: DEFAULT_SETS,
    targetReps: DEFAULT_REPS,
    equipment: exercise.equipment,
  });
  persist();
  render();
  renderPicker();
  showToast(`Added ${exercise.name}`);
}

function removeCatalogExercise(exercise) {
  const day = selectedDay();
  if (!day) return;
  const index = day.exercises.findLastIndex((item) => item.name === exercise.name);
  if (index < 0) return;
  day.exercises.splice(index, 1);
  persist();
  render();
  renderPicker();
}

function dayHasExercise(name) {
  return Boolean(selectedDay()?.exercises.some((item) => item.name === name));
}

function buildExportObject() {
  const exportedAt = iso8601();
  const createdSource = state.createdAt ? new Date(state.createdAt) : new Date();
  const createdAt = Number.isNaN(createdSource.getTime()) ? exportedAt : iso8601(createdSource);
  return {
    version: 1,
    exportedAt,
    program: {
      uuid: state.uuid,
      name: state.name.trim(),
      isActive: false,
      createdAt,
      days: state.days.map((day, dayIndex) => ({
        uuid: day.uuid,
        name: day.name.trim() || `Day ${dayIndex + 1}`,
        sortIndex: dayIndex,
        exercises: day.exercises.map((item, exerciseIndex) => ({
          name: item.name,
          primaryMuscles: item.primaryMuscles || [],
          secondaryMuscles: item.secondaryMuscles || [],
          targetSets: item.targetSets,
          targetReps: DEFAULT_REPS,
          sortIndex: exerciseIndex,
          equipment: item.equipment || inferEquipment(item.name),
        })),
      })),
    },
  };
}

function downloadExport() {
  if (!canExport()) return;
  const json = prettyJSON(buildExportObject());
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = sanitizeFilename(state.name.trim());
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
  showToast("Exported program JSON");
}

function parseISODate(value) {
  if (typeof value !== "string" || !value) return iso8601();
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return iso8601();
  return iso8601(date);
}

function importTemplate(raw) {
  const file = typeof raw === "string" ? JSON.parse(raw) : raw;
  if (!file || typeof file !== "object") throw new Error("Invalid JSON");
  const program = file.program;
  if (!program || typeof program !== "object") throw new Error("Missing program object");
  if (typeof program.name !== "string") throw new Error("Missing program name");
  if (!Array.isArray(program.days)) throw new Error("Missing days array");

  state = {
    uuid: typeof program.uuid === "string" && program.uuid ? program.uuid : crypto.randomUUID(),
    name: program.name,
    createdAt: parseISODate(program.createdAt),
    days: program.days
      .slice()
      .sort((a, b) => (a.sortIndex ?? 0) - (b.sortIndex ?? 0))
      .map((day, index) => ({
        uuid: typeof day.uuid === "string" && day.uuid ? day.uuid : crypto.randomUUID(),
        name: day.name || `Day ${index + 1}`,
        exercises: Array.isArray(day.exercises)
          ? day.exercises
              .slice()
              .sort((a, b) => (a.sortIndex ?? 0) - (b.sortIndex ?? 0))
              .map((item) => {
                const catalogItem = byName.get(String(item.name || "").toLowerCase());
                return {
                  catalogId: catalogItem?.id,
                  name: catalogItem?.name || item.name,
                  primaryMuscles: catalogItem?.primary || item.primaryMuscles || [],
                  secondaryMuscles: catalogItem?.secondary || item.secondaryMuscles || [],
                  targetSets: Number(item.targetSets) > 0 ? Number(item.targetSets) : DEFAULT_SETS,
                  targetReps: Number(item.targetReps) > 0 ? Number(item.targetReps) : DEFAULT_REPS,
                  equipment: item.equipment || catalogItem?.equipment || inferEquipment(item.name || ""),
                };
              })
          : [],
      })),
  };
  selectedDayId = state.days[0]?.uuid ?? null;
  persist();
  render();
  showToast("Imported program JSON");
}

function populateFilters() {
  for (const category of CATEGORIES) {
    els.filterCategory.insertAdjacentHTML("beforeend", `<option value="${category}">${category}</option>`);
  }
  for (const item of EQUIPMENT) {
    els.filterEquipment.insertAdjacentHTML("beforeend", `<option value="${item.id}">${item.title}</option>`);
  }
  for (const muscle of MUSCLES) {
    els.filterMuscle.insertAdjacentHTML("beforeend", `<option value="${muscle}">${muscle}</option>`);
  }
}

function filteredCatalog() {
  const query = els.pickerSearch.value.trim().toLowerCase();
  const category = els.filterCategory.value;
  const equipment = els.filterEquipment.value;
  const muscle = els.filterMuscle.value;
  return displaySorted(
    catalog.filter((item) => {
      const matchesQuery =
        !query ||
        item.name.toLowerCase().includes(query) ||
        item.primary.some((name) => name.toLowerCase().includes(query));
      const matchesCategory = !category || item.category === category;
      const matchesEquipment = !equipment || item.equipment === equipment;
      const matchesMuscle = !muscle || item.primary.includes(muscle) || item.secondary.includes(muscle);
      return matchesQuery && matchesCategory && matchesEquipment && matchesMuscle;
    })
  );
}

function filtersAreClear() {
  return !els.pickerSearch.value.trim() && !els.filterCategory.value && !els.filterEquipment.value && !els.filterMuscle.value;
}

function renderPicker() {
  document.querySelector("[data-filter-reset]").classList.toggle("selected", filtersAreClear());
  const items = filteredCatalog();
  if (!items.length) {
    els.pickerBody.innerHTML = `<p class="picker-empty">No exercises match your search or filters.</p>`;
    return;
  }
  const groups = CATEGORIES.map((category) => [category, items.filter((item) => item.category === category)]).filter(
    ([, list]) => list.length
  );
  els.pickerBody.innerHTML = groups
    .map(
      ([category, list]) => `
      <section class="picker-group">
        <h3>${category}</h3>
        <div class="card-grid">
          ${list
            .map((item) => {
              const added = dayHasExercise(item.name);
              return `
                <button type="button" class="picker-card${added ? " added" : ""}" data-id="${item.id}">
                  ${photoMarkup(item, true)}
                  <div class="card-body">
                    <h4>${escapeHTML(item.name)}</h4>
                    <p>${escapeHTML(displayMuscles(item.primary).join(" · "))}</p>
                    <span class="badge${added ? " on" : ""}">${added ? "Added" : equipmentTitle(item.equipment)}</span>
                  </div>
                </button>`;
            })
            .join("")}
        </div>
      </section>`
    )
    .join("");
}

function openPicker() {
  if (!selectedDay()) return;
  els.picker.classList.remove("hidden");
  els.pickerSearch.value = "";
  els.filterCategory.value = "";
  els.filterEquipment.value = "";
  els.filterMuscle.value = "";
  renderPicker();
  els.pickerSearch.focus();
}

function closePicker() {
  els.picker.classList.add("hidden");
}

function clamp(value) {
  return Math.max(1, Math.min(99, value));
}

async function init() {
  populateFilters();
  const response = await fetch("data/exercises.json");
  if (!response.ok) throw new Error("Could not load exercise catalog");
  catalog = await response.json();
  byName = new Map(catalog.map((item) => [item.name.toLowerCase(), item]));
  refreshFoldedBackMuscles();
  restore();
  render();

  els.programName.addEventListener("input", () => {
    state.name = els.programName.value;
    persist();
    els.exportBtn.disabled = !canExport();
    els.exportBtn.title = canExport()
      ? "Download ProgramTemplateFile JSON"
      : "Add a program name and at least one day to export";
    renderOverview();
  });

  els.addDayBtn.addEventListener("click", addDay);
  els.dayName.addEventListener("input", () => {
    const day = selectedDay();
    if (!day) return;
    day.name = els.dayName.value;
    persist();
    const row = els.dayList.querySelector(`[data-day-id="${day.uuid}"] strong`);
    if (row) row.textContent = day.name || "Untitled day";
  });

  els.dayList.addEventListener("click", (event) => {
    const row = event.target.closest("[data-day-id]");
    if (!row) return;
    if (event.target.closest(".delete-day")) {
      deleteDay(row.dataset.dayId);
      return;
    }
    selectedDayId = row.dataset.dayId;
    render();
  });

  bindListDrag(els.dayList, (rows) => {
    const byId = new Map(state.days.map((day) => [day.uuid, day]));
    const next = rows.map((row) => byId.get(row.dataset.dayId)).filter(Boolean);
    if (next.length === state.days.length) state.days = next;
    persist();
    render();
  });

  bindListDrag(els.exerciseList, (rows) => {
    const day = selectedDay();
    if (!day) return;
    const next = rows
      .map((row) => day.exercises[Number(row.dataset.index)])
      .filter(Boolean);
    if (next.length === day.exercises.length) day.exercises = next;
    persist();
    render();
  });

  els.exerciseList.addEventListener("click", (event) => {
    const day = selectedDay();
    if (!day) return;
    const remove = event.target.closest(".remove-exercise");
    if (remove) {
      day.exercises.splice(Number(remove.dataset.index), 1);
      persist();
      render();
      return;
    }
    const deltaBtn = event.target.closest(".stepper button");
    if (!deltaBtn) return;
    const stepper = deltaBtn.closest(".stepper");
    const index = Number(stepper.dataset.index);
    const field = stepper.dataset.field;
    day.exercises[index][field] = clamp(day.exercises[index][field] + Number(deltaBtn.dataset.delta));
    persist();
    render();
  });

  els.addExerciseBtn.addEventListener("click", openPicker);
  els.pickerClose.addEventListener("click", closePicker);
  els.picker.addEventListener("click", (event) => {
    if (event.target === els.picker) closePicker();
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !els.picker.classList.contains("hidden")) closePicker();
  });
  els.pickerSearch.addEventListener("input", renderPicker);
  els.filterCategory.addEventListener("change", renderPicker);
  els.filterEquipment.addEventListener("change", renderPicker);
  els.filterMuscle.addEventListener("change", renderPicker);
  document.querySelector("[data-filter-reset]").addEventListener("click", () => {
    els.pickerSearch.value = "";
    els.filterCategory.value = "";
    els.filterEquipment.value = "";
    els.filterMuscle.value = "";
    renderPicker();
  });
  els.pickerBody.addEventListener("click", (event) => {
    const card = event.target.closest(".picker-card");
    if (!card) return;
    const exercise = catalog.find((item) => item.id === card.dataset.id);
    if (!exercise) return;
    if (dayHasExercise(exercise.name)) removeCatalogExercise(exercise);
    else addCatalogExercise(exercise);
  });

  els.overview.addEventListener("click", (event) => {
    const button = event.target.closest("[data-muscle-view]");
    if (!button || !els.overview.contains(button)) return;
    setMuscleView(button.dataset.muscleView);
  });

  els.exportBtn.addEventListener("click", downloadExport);
  els.importBtn.addEventListener("click", () => els.importFile.click());
  els.importFile.addEventListener("change", async () => {
    const file = els.importFile.files[0];
    els.importFile.value = "";
    if (!file) return;
    try {
      importTemplate(await file.text());
    } catch (error) {
      showToast(error.message || "Could not import JSON");
    }
  });
}

init().catch((error) => {
  showToast(error.message || "Failed to load catalog");
});
