$wc = new-object System.Net.WebClient 
$wc.UploadFile("http://octopus.holding.intra/api/packages/raw?apiKey=API-KEYBFQJ0DXYZXXXX1I3K1SI", "some-package.1.2.0.nupkg")