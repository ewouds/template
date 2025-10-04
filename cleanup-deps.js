import { execSync } from "child_process";
import { dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function run(cmd, cwd) {
  try {
    return execSync(cmd, { encoding: "utf8", stdio: "pipe", cwd });
  } catch (e) {
    return e.stdout ? e.stdout.toString() : "";
  }
}

async function main() {
  // Ensure depcheck is installed
  try {
    await import("depcheck");
  } catch {
    console.log("Installing depcheck...");
    run("npm install depcheck --no-save");
  }

  // Run depcheck and parse output
  const { default: depcheck } = await import("depcheck");
  const cwd = __dirname;

  try {
    const unused = await depcheck(cwd, {});
    console.log("Checking for unused dependencies...");
    const unusedDeps = unused.dependencies || [];
    const unusedDevDeps = unused.devDependencies || [];
    const allUnused = [...unusedDeps, ...unusedDevDeps];

    if (allUnused.length === 0) {
      console.log("No unused dependencies found!");
      return;
    }

    console.log("Unused dependencies:", allUnused.join(", "));
    // Uninstall unused dependencies
    const uninstallCmd = `npm uninstall ${allUnused.join(" ")}`;
    console.log(`Running: ${uninstallCmd}`);

    try {
      execSync(uninstallCmd, { stdio: "inherit", cwd });
      console.log("Unused dependencies removed.");
    } catch (err) {
      console.error("Error uninstalling dependencies:", err.message);
    }
  } catch (err) {
    console.error("Error analyzing dependencies:", err.message);
  }
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
