import { describe, it, expect, beforeAll } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { analysisTargets, inferEquipment, prettyJSON, iso8601 } from "../app.js";

// Shared with WorkoutAppTests/Contract/ProgramTemplateContractTests.swift, which
// decodes the same two files via ProgramTemplateService. If either side's schema
// drifts from the other, one of these two test suites should fail.
const contractDir = path.resolve(fileURLToPath(import.meta.url), "../../../contract");
const schema = JSON.parse(readFileSync(path.join(contractDir, "program-template.schema.json"), "utf8"));
const fixture = JSON.parse(readFileSync(path.join(contractDir, "program-template.fixture.json"), "utf8"));

let validate;
beforeAll(() => {
  const ajv = new Ajv({ strict: true });
  addFormats(ajv);
  validate = ajv.compile(schema);
});

describe("shared program-template contract", () => {
  it("the checked-in fixture validates against the shared schema", () => {
    const valid = validate(fixture);
    expect(valid, JSON.stringify(validate.errors)).toBe(true);
  });

  it("a program-builder-style export (built with the app's own pure functions) validates against the schema", () => {
    // Mirrors buildExportObject()'s shape without depending on its module-global
    // `state`/`DEFAULT_REPS` — it exercises the same pure helpers the real
    // export path uses (analysisTargets, inferEquipment, iso8601) with local data.
    const exercise = {
      name: "Barbell Row",
      primaryMuscles: ["Lats"],
      secondaryMuscles: ["Rhomboids", "Biceps", "Lats"],
      targetSets: 4,
    };
    const mapped = analysisTargets(exercise);
    const exported = {
      version: 1,
      exportedAt: iso8601(),
      program: {
        uuid: "44444444-4444-4444-4444-444444444444",
        name: "Pull Day",
        isActive: false,
        createdAt: iso8601(),
        days: [
          {
            uuid: "55555555-5555-5555-5555-555555555555",
            name: "Pull",
            sortIndex: 0,
            exercises: [
              {
                name: exercise.name,
                primaryMuscles: mapped.primary,
                secondaryMuscles: mapped.secondary,
                targetSets: exercise.targetSets,
                targetReps: 8,
                sortIndex: 0,
                equipment: inferEquipment(exercise.name),
              },
            ],
          },
        ],
      },
    };

    // A muscle listed as both primary and secondary must not appear in both
    // arrays in the exported JSON either — same rule the schema and the iOS
    // ProgramOverviewStats side both rely on.
    expect(exported.program.days[0].exercises[0].secondaryMuscles).not.toContain("Lats");

    const valid = validate(exported);
    expect(valid, JSON.stringify(validate.errors)).toBe(true);
  });

  it("rejects a payload missing a required field", () => {
    const broken = JSON.parse(JSON.stringify(fixture));
    delete broken.program.name;
    expect(validate(broken)).toBe(false);
  });

  it("rejects an unknown top-level property (schema is additionalProperties: false)", () => {
    const broken = JSON.parse(JSON.stringify(fixture));
    broken.unexpectedField = true;
    expect(validate(broken)).toBe(false);
  });

  it("prettyJSON output for the fixture still validates (formatting round-trip)", () => {
    const reparsed = JSON.parse(prettyJSON(fixture));
    expect(validate(reparsed)).toBe(true);
  });
});
