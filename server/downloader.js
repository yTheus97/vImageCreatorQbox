const fs = require('fs');
const https = require('https');
const path = require('path');

onNet('renzu_vehthumb:download_js', (model, url) => {

    const resourcePath = GetResourcePath(GetCurrentResourceName());

    const dest = path.join(resourcePath, 'output', `${model}.png`);

    const file = fs.createWriteStream(dest);

    https.get(url, (response) => {
        response.pipe(file);
        
        file.on('finish', () => {
            file.close();
            console.log(`^2[Sucesso] Imagem salva: output/${model}.png^0`);
        });
    }).on('error', (err) => {
        fs.unlink(dest, () => {});
        console.log(`^1[Erro JS] Falha ao baixar ${model}: ${err.message}^0`);
    });
});
