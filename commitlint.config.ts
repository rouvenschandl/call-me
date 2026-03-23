import type { UserConfig } from "@commitlint/types";

const Configuration: UserConfig = {
  extends: ["@commitlint/config-conventional"],
  ignores: [
    (commit: string) => commit.startsWith("chore(release):"), // Ignore release commits
    (message: string) => message.startsWith("chore: bump"), // Ignore dependabot commits
  ],
};

export default Configuration;
