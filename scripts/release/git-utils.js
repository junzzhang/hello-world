'use strict';

const { exec } = require('child_process');

module.exports = {
    async getCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --current-branch', (error, stdout, stderr) => {
                if (error) {
                    // error.code
                    return reject(new Error("获取当前分支名时出错。"));
                }
                resolve(stdout.replace(/^\s+|\s+$/, ''));
            })
        })
    },
    async getAllEnableMergeBackBranches(strExcludeBranches) {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --enable-merge-back-branches "' + strExcludeBranches + '"', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.split(/\s+/).filter(item => !!item));
            })
        })
    },
    async isCurrentBranchClean() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --is-current-branch-clean', (error, stdout, stderr) => {
                if (error) {
                    return reject(false);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async pullCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --pull-current-branch', (error, stdout, stderr) => {
                if (error) {
                    return reject(false);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async pushCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --push-current-branch', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async removeRemoteBranch(localBranchName) {
        return new Promise((resolve, reject) => {
            exec(`bash ./scripts/git-helper.sh --remove-remote-branch ${localBranchName}`, (error, stdout, stderr) => {
                resolve(error ? false : true);
            })
        })
    },
    async removeLocalBranch(localBranchName) {
        return new Promise((resolve, reject) => {
            exec(`bash ./scripts/git-helper.sh --remove-local-branch ${localBranchName}`, (error, stdout, stderr) => {
                resolve(error ? false : true);
            })
        })
    },
    async mergeFrom(to, from, isPushToOrigin) {
        return new Promise((resolve, reject) => {
            exec(`bash ./scripts/git-helper.sh --merge-from ${to} ${from} ${isPushToOrigin || false}`, (error, stdout, stderr) => {
                if (error) {
                    return resolve(stderr.replace(/^\s+|\s+$/, '') >> 0);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') >> 0);
            })
        })
    },
    async standardVersion() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --standard-version', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async createLocalTag(tag, tagDescription) {
        return new Promise((resolve, reject) => {
            // const strTagDescription = tagDescription.replace(/\n/g, "\\n");
            const strDesc = (tagDescription || tag).replace(/\"/g, "\\\"").replace(/\n/g, '" -m "');
            const cmd = `git tag -a ${tag} -m "${strDesc}"`;

            exec(cmd, (error, stdout, stderr) => {
                if (error) {
                    return reject(new Error(`Tag ${tag} 创建时错误。`));
                }
                exec("git push --follow-tags origin master", (error, stdout, stderr) => {
                    if (error) {
                        return reject(new Error(`Tag ${tag} 创建时错误。`));
                    }

                    exec('git push --follow-tags origin master', (err, result) => {
                        if (err) {
                            return reject(new Error(`分支 master 代码没有成功推到远程仓库，接下来你最好手动进行发版操作。`));
                        }
                        resolve(true);
                    });
                });
            })
        })
    },
    async release(mergeBackBranches) {
        return new Promise((resolve, reject) => {
            const strMergeBackBranches = mergeBackBranches.join(" ");

            const ll = exec(`bash ./scripts/release.sh "${strMergeBackBranches}"`, (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout);
            });

            ll.stdout.on('data', (data) => {
                console.log(`${data}`);
            });
        })
    }
};
