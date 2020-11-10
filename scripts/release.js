'use strict';
const inquirer = require('inquirer');
const { isCurrentBranchClean, getCurrentBranch, getAllEnableMergeBackBranches, release } = require('./git-helper');

async function start() {
    const currentBranch = await getCurrentBranch();
    const { isPublish } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'isPublish',
            message: `确定要发布当前分支 ${currentBranch} 吗？`,
            default: false,
        }
    ]);

    if (!isPublish) {
        throw new Error('发布失败：您取消了发布当前分支。');
    }

    const isClean = await isCurrentBranchClean();
    if (!isClean) {
        throw new Error('发布失败：请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。');
    }

    let defaultTag = currentBranch.match(/(\d+\.){3}\d+/) || void 0;
    if (defaultTag) {
        defaultTag = defaultTag[0];
    }
    const enableMergeBackbranches = await getAllEnableMergeBackBranches(currentBranch);

    const questions = [
        {
            type: 'input',
            name: 'tagName',
            message: '请输入 tag 号：',
            default: defaultTag,
            validate: function (value) {
                if (/^(\d+\.){3}\d+$/.test(value)) {
                    return true;
                }

                return '请输入正确的版本号！';
            },
        },
        {
            type: 'editor',
            name: 'tagDescription',
            message: '请输入 tag 描述信息：',
            validate: function (text) {
                if (!(text.replace(/^\s+|\s+$/, ''))) {
                    return 'Tag 描述信息不能为空.';
                }

                return true;
            },
        },
        {
            type: 'checkbox',
            message: '请选择发布完成后，想要回合的分支：',
            name: 'mergeBackBranches',
            choices: enableMergeBackbranches.map(item => ({name: item})),
            default: enableMergeBackbranches,
            validate: function (answer) {
                // if (answer.length < 1) {
                //     return 'You must choose at least one topping.';
                // }
                return true;
            },
        }
    ];

    const { tagName, tagDescription, mergeBackBranches } = await inquirer.prompt(questions);

    return release(currentBranch, tagName, tagDescription, mergeBackBranches);
}

start().catch(err => {
    console.log("\x1b[31m%s\x1b[0m", err.message);
});


// var BottomBar = require('inquirer/lib/ui/bottom-bar');
//
// var loader = ['/ Installing', '| Installing', '\\ Installing', '- Installing'];
// var i = 4;
// var ui = new BottomBar({ bottomBar: loader[i % 4] });
//
// setInterval(() => {
//     ui.updateBottomBar(loader[i++ % 4]);
// }, 300);