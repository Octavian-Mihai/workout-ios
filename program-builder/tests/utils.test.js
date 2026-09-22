import { describe, it, expect } from "vitest";
import {
  sortValue,
  prettyJSON,
  sanitizeFilename,
  inferEquipment,
  containsAny,
  inferPattern,
  displaySorted,
  equipmentTitle,
  plannedSetCount,
  estimatedWorkoutMinutes,
  estimatedWorkoutLabel,
  dayMetaLabel,
  escapeHTML,
  parseISODate,
  clamp,
  iso8601,
} from "../app.js";

describe("sortValue / prettyJSON", () => {
  it("sorts object keys recursively, mirroring the iOS export's .sortedKeys encoding", () => {
    const input = { b: 2, a: { d: 4, c: 3 } };
    expect(sortValue(input)).toEqual({ a: { c: 3, d: 4 }, b: 2 });
  });

  it("sorts keys inside array elements without reordering the array itself", () => {
    const input = [{ b: 1, a: 2 }, { d: 1, c: 2 }];
    expect(sortValue(input)).toEqual([{ a: 2, b: 1 }, { c: 2, d: 1 }]);
  });

  it("prettyJSON pretty-prints with sorted keys and a trailing newline", () => {
    const output = prettyJSON({ b: 1, a: 2 });
    expect(output).toBe('{\n  "a": 2,\n  "b": 1\n}\n');
  });
});

describe("sanitizeFilename", () => {
  it("lowercases, replaces runs of non-alphanumerics with a dash, and trims edge dashes", () => {
    expect(sanitizeFilename("Push Pull Legs!")).toBe("program-push-pull-legs.json");
  });

  it("falls back to a generic filename when nothing alphanumeric remains", () => {
    expect(sanitizeFilename("!!!")).toBe("program.json");
  });
});

describe("inferEquipment", () => {
  it("recognizes bodyweight movements even when another keyword like machine dip could match", () => {
    expect(inferEquipment("Push-up")).toBe("bodyweight");
    expect(inferEquipment("Pull-up")).toBe("bodyweight");
  });

  it("does not classify machine dips as bodyweight", () => {
    expect(inferEquipment("Machine Dip")).toBe("machine");
  });

  it("classifies a barbell squat as barbell but excludes hack squat from that match", () => {
    expect(inferEquipment("Back Squat")).toBe("barbell");
    // The barbell-squat heuristic explicitly excludes "hack", and no other
    // keyword list matches "hack squat" either, so it falls through to the
    // bodyweight default rather than being recognized as a machine.
    expect(inferEquipment("Hack Squat")).toBe("bodyweight");
  });

  it("falls back to bodyweight for an unrecognized exercise name", () => {
    expect(inferEquipment("Unknown Movement")).toBe("bodyweight");
  });
});

describe("containsAny / inferPattern", () => {
  it("containsAny is true only when at least one needle is present", () => {
    expect(containsAny("barbell row", ["row", "curl"])).toBe(true);
    expect(containsAny("barbell bench", ["row", "curl"])).toBe(false);
  });

  it("an explicit pattern always wins over inference", () => {
    expect(inferPattern("Bench Press", "Push", "Custom Pattern")).toBe("Custom Pattern");
  });

  it("infers Horizontal Pull for a barbell row without an explicit pattern", () => {
    expect(inferPattern("Barbell Row", "Pull", undefined)).toBe("Horizontal Pull");
  });

  it("infers Vertical Push for an overhead press", () => {
    expect(inferPattern("Overhead Press", "Push", undefined)).toBe("Vertical Push");
  });
});

describe("displaySorted", () => {
  it("orders items by PATTERN_RANK, then alphabetically within the same pattern", () => {
    const items = [
      { name: "Barbell Row", category: "Pull" },
      { name: "Pull-up", category: "Pull" },
      { name: "Chin-up", category: "Pull" },
    ];
    const sorted = displaySorted(items).map((item) => item.name);
    // Vertical Pull (Pull-up, Chin-up alphabetically) ranks above Horizontal Pull (Barbell Row).
    expect(sorted).toEqual(["Chin-up", "Pull-up", "Barbell Row"]);
  });
});

describe("equipmentTitle", () => {
  it("resolves a known equipment id to its display title", () => {
    expect(equipmentTitle("barbell")).toBe("Barbell");
  });

  it("falls back to the raw id for an unknown value", () => {
    expect(equipmentTitle("mystery")).toBe("mystery");
  });
});

describe("workout duration estimates", () => {
  it("plannedSetCount sums target sets, ignoring negatives", () => {
    expect(plannedSetCount([{ targetSets: 3 }, { targetSets: -1 }, { targetSets: 4 }])).toBe(7);
  });

  it("plannedSetCount treats a missing/undefined list as zero", () => {
    expect(plannedSetCount(undefined)).toBe(0);
  });

  it("estimatedWorkoutMinutes returns null for an empty day", () => {
    expect(estimatedWorkoutMinutes([])).toBeNull();
  });

  it("estimatedWorkoutMinutes matches the hand-computed formula", () => {
    // MINUTES_PER_SET = (90 + 45) / 60 = 2.25; SETUP_MINUTES_PER_EXERCISE = 1.
    // 2 exercises, 6 total sets -> 6 * 2.25 + 2 * 1 = 15.5 -> rounds to 16.
    const minutes = estimatedWorkoutMinutes([{ targetSets: 3 }, { targetSets: 3 }]);
    expect(minutes).toBe(16);
  });

  it("estimatedWorkoutLabel formats the minute estimate, or empty string when there is none", () => {
    expect(estimatedWorkoutLabel([{ targetSets: 3 }, { targetSets: 3 }])).toBe("~16 min");
    expect(estimatedWorkoutLabel([])).toBe("");
  });

  it("dayMetaLabel pluralizes the exercise count and appends the duration estimate", () => {
    const day = { exercises: [{ targetSets: 3 }, { targetSets: 3 }] };
    expect(dayMetaLabel(day)).toBe("2 exercises · ~16 min");
  });

  it("dayMetaLabel omits the duration estimate entirely for an empty day", () => {
    expect(dayMetaLabel({ exercises: [] })).toBe("0 exercises");
  });

  it("dayMetaLabel uses the singular 'exercise' for exactly one", () => {
    // 1 exercise, 3 sets -> 3 * 2.25 + 1 * 1 = 7.75 -> rounds to 8.
    const day = { exercises: [{ targetSets: 3 }] };
    expect(dayMetaLabel(day)).toBe("1 exercise · ~8 min");
  });
});

describe("escapeHTML", () => {
  it("escapes &, <, >, and \" but leaves single quotes untouched", () => {
    expect(escapeHTML(`<b>"a" & 'b'</b>`)).toBe("&lt;b&gt;&quot;a&quot; &amp; 'b'&lt;/b&gt;");
  });
});

describe("clamp", () => {
  it("clamps to the 1-99 range used by the set/rep steppers", () => {
    expect(clamp(0)).toBe(1);
    expect(clamp(150)).toBe(99);
    expect(clamp(50)).toBe(50);
  });
});

describe("parseISODate / iso8601", () => {
  it("round-trips a valid ISO date without the milliseconds Date normally adds", () => {
    expect(parseISODate("2024-03-01T09:00:00Z")).toBe("2024-03-01T09:00:00Z");
  });

  it("falls back to the current time for an invalid or missing date", () => {
    const fallback = parseISODate("not a date");
    expect(() => new Date(fallback)).not.toThrow();
    expect(new Date(fallback).toISOString().slice(0, 4)).toBe(String(new Date().getFullYear()));
  });

  it("iso8601 strips milliseconds from the ISO string", () => {
    const date = new Date("2024-03-01T09:00:00.123Z");
    expect(iso8601(date)).toBe("2024-03-01T09:00:00Z");
  });
});
