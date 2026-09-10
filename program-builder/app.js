const STORAGE_KEY = "program-builder:draft";
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
  "Upper Back",
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
};

let catalog = [];
let byName = new Map();
let state = emptyState();
let selectedDayId = null;
let toastTimer = 0;

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
  if (exercise?.image) {
    const src = `images/exercises/${exercise.image}`;
    return `<img class="thumb" src="${src}" alt="" />`;
  }
  return `<div class="placeholder${large ? " large" : ""}">Photo coming soon</div>`;
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
            <p>${escapeHTML((item.primaryMuscles || []).join(" · ") || "—")}</p>
          </div>
          <div class="stepper" data-field="targetSets" data-index="${index}">
            <span class="label">Sets</span>
            <button type="button" data-delta="-1" aria-label="Fewer sets">−</button>
            <strong>${item.targetSets}</strong>
            <button type="button" data-delta="1" aria-label="More sets">+</button>
          </div>
          <div class="stepper" data-field="targetReps" data-index="${index}">
            <span class="label">Reps</span>
            <button type="button" data-delta="-1" aria-label="Fewer reps">−</button>
            <strong>${item.targetReps}</strong>
            <button type="button" data-delta="1" aria-label="More reps">+</button>
          </div>
          <button type="button" class="btn btn-danger remove-exercise" data-index="${index}">Remove</button>
        </li>`;
    })
    .join("");
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
          targetReps: item.targetReps,
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
                    <p>${escapeHTML(item.primary.join(" · "))}</p>
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
  restore();
  render();

  els.programName.addEventListener("input", () => {
    state.name = els.programName.value;
    persist();
    els.exportBtn.disabled = !canExport();
    els.exportBtn.title = canExport()
      ? "Download ProgramTemplateFile JSON"
      : "Add a program name and at least one day to export";
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
