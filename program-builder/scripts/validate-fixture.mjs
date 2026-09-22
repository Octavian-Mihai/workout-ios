#!/usr/bin/env node
// Standalone schema-compat check: validates ../contract/program-template.fixture.json
// against ../contract/program-template.schema.json. Run via `npm run schema:check`
// from program-builder/ (where ajv is a devDependency) so module resolution works.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import Ajv from "ajv";
import addFormats from "ajv-formats";

const contractDir = path.resolve(fileURLToPath(import.meta.url), "../../../contract");
const schema = JSON.parse(readFileSync(path.join(contractDir, "program-template.schema.json"), "utf8"));
const fixture = JSON.parse(readFileSync(path.join(contractDir, "program-template.fixture.json"), "utf8"));

const ajv = new Ajv({ strict: true });
addFormats(ajv);
const validate = ajv.compile(schema);

if (!validate(fixture)) {
  console.error("contract/program-template.fixture.json does not match contract/program-template.schema.json:");
  console.error(JSON.stringify(validate.errors, null, 2));
  process.exit(1);
}

console.log("contract/program-template.fixture.json is valid against the schema.");
