import { describe, it, expect } from "vitest";
import {
  analysisTargets,
  mapCatalogMuscle,
  mapCatalogMuscles,
  regionName,
  sortCredit,
  overviewInsights,
} from "../app.js";

// The 20 muscle groups the analysis pipeline recognizes — must stay in lockstep
// with the iOS app's MuscleGroup enum (WorkoutApp/Models/ExerciseCatalog.swift)
// since both sides analyze the same exported program JSON.
const ALL_MUSCLES = [
  "Chest",
  "Anterior Delts",
  "Lateral Delts",
  "Triceps",
  "Core & Abs",
  "Lats",
  "Rhomboids",
  "Traps",
  "Erectors",
  "Posterior Delts",
  "Biceps",
  "Forearms & Grip",
  "Quadriceps",
  "Hamstrings",
  "Glutes",
  "Calves",
  "Tibialis",
  "Adductors",
  "Abductors",
  "Hip Flexors",
];

describe("muscle mapping", () => {
  it("recognizes all 20 muscle groups", () => {
    expect(ALL_MUSCLES).toHaveLength(20);
    for (const muscle of ALL_MUSCLES) {
      expect(mapCatalogMuscle(muscle)).toBe(muscle);
    }
  });

  it("resolves legacy/alternate catalog names, matching the iOS MuscleGroup.parse aliases", () => {
    expect(mapCatalogMuscle("Front Delts")).toBe("Anterior Delts");
    expect(mapCatalogMuscle("Side Delts")).toBe("Lateral Delts");
    expect(mapCatalogMuscle("Rear Delts")).toBe("Posterior Delts");
    expect(mapCatalogMuscle("Core")).toBe("Core & Abs");
    expect(mapCatalogMuscle("Upper Back")).toBe("Rhomboids");
    expect(mapCatalogMuscle("Lower Back")).toBe("Erectors");
    expect(mapCatalogMuscle("Forearms")).toBe("Forearms & Grip");
    expect(mapCatalogMuscle("Quads")).toBe("Quadriceps");
  });

  it("returns null for a name with no known mapping", () => {
    expect(mapCatalogMuscle("Not A Real Muscle")).toBeNull();
  });

  it("every muscle group maps to one of the four regions used by overviewInsights", () => {
    const knownRegions = new Set(["Upper body", "Arms", "Lower body", "Trunk"]);
    for (const muscle of ALL_MUSCLES) {
      expect(knownRegions.has(regionName(muscle))).toBe(true);
    }
  });

  it("spot-checks region assignments against the iOS mapping", () => {
    expect(regionName("Chest")).toBe("Upper body");
    expect(regionName("Biceps")).toBe("Arms");
    expect(regionName("Quadriceps")).toBe("Lower body");
    expect(regionName("Core & Abs")).toBe("Trunk");
  });

  it("a muscle listed as both primary and secondary is credited only as primary", () => {
    const targets = analysisTargets({
      primaryMuscles: ["Chest"],
      secondaryMuscles: ["Chest", "Triceps"],
    });
    expect(targets.primary).toEqual(["Chest"]);
    expect(targets.secondary).toEqual(["Triceps"]);
  });

  it("deduplicates repeated muscle names and drops unmapped ones", () => {
    const targets = analysisTargets({
      primaryMuscles: ["Chest", "Chest", "Not A Real Muscle"],
      secondaryMuscles: [],
    });
    expect(targets.primary).toEqual(["Chest"]);
  });
});

describe("sortCredit", () => {
  it("uses setCredit when usingSets is true, exerciseCredit otherwise", () => {
    const row = { exerciseCredit: 1, setCredit: 4 };
    expect(sortCredit(row, true)).toBe(4);
    expect(sortCredit(row, false)).toBe(1);
  });
});

describe("overviewInsights", () => {
  it("with no exercises, returns only the empty-rotation message", () => {
    const insights = overviewInsights([], 0, 0);
    expect(insights).toEqual([
      "No exercises in this rotation yet. Add days and lifts to see the split.",
    ]);
  });

  it("an all-lower-body program flags missing upper-body work but not missing arms", () => {
    const rows = [
      { name: "Quadriceps", region: "Lower body", exerciseCredit: 1, setCredit: 3 },
      { name: "Hamstrings", region: "Lower body", exerciseCredit: 1, setCredit: 3 },
    ];
    const insights = overviewInsights(rows, 2, 6);
    expect(insights.some((note) => note.includes("No upper-body work"))).toBe(true);
    expect(insights.some((note) => note.includes("arm credit"))).toBe(false);
  });

  it("a strong push/pull imbalance produces the pressing-outweighs-pulling note", () => {
    const rows = [
      { name: "Chest", region: "Upper body", exerciseCredit: 1, setCredit: 10 },
      { name: "Lats", region: "Upper body", exerciseCredit: 1, setCredit: 2 },
    ];
    const insights = overviewInsights(rows, 2, 12);
    expect(insights.some((note) => note.includes("Pressing outweighs pulling"))).toBe(true);
  });

  it("zero planned sets falls back to exercise-credit wording", () => {
    const rows = [{ name: "Chest", region: "Upper body", exerciseCredit: 1, setCredit: 0 }];
    const insights = overviewInsights(rows, 1, 0);
    expect(insights[0]).toContain("Target sets are still 0");
  });
});
