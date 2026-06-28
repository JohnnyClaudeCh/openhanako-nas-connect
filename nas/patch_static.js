const fs = require('fs');

// 如果路径不同，改成你的 HanaAgent 源码目录
const file = '/vol1/1000/Hanako/server/routes/mobile-static.ts';
let code = fs.readFileSync(file, 'utf-8');

// 把 settings.html 加到白名单
code = code.replace(
  `decoded !== "manifest.webmanifest"`,
  `decoded !== "settings.html" && decoded !== "manifest.webmanifest"`
);

fs.writeFileSync(file, code);
console.log('patched mobile-static.ts');
