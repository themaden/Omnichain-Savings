const { ethers } = require("ethers");
const chalk = require("chalk"); // Renkli çıktılar için

// --- AYARLAR ---
// Foundry Anvil (Localhost) varsayılan Private Key'i (Account 0)
const PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; 
const RPC_URL = "http://127.0.0.1:8545";

// Buraya DEPLOY ettikten sonra kontrat adresini yazacağız (Şimdilik boş bırak)
const SOURCE_VAULT_ADDRESS = "BURAYA_ADRES_GELECEK"; 

// Sadece ihtiyacımız olan fonksiyonun ABI'si
const VAULT_ABI = [
    "function bridgeToStrategy(uint64 _destinationChainSelector, address _receiver, uint256 _amount) external"
];

async function main() {
    console.clear();
    console.log(chalk.green.bold("🤖 OMNICHAIN AI AGENT BAŞLATILIYOR..."));
    console.log(chalk.gray("------------------------------------------------"));

    // Blockchain bağlantısı
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    // Eğer adres girilmediyse uyarı ver
    if (SOURCE_VAULT_ADDRESS === "BURAYA_ADRES_GELECEK") {
        console.log(chalk.red.bold("HATA: Lütfen SourceVault kontrat adresini koda ekleyin!"));
        return;
    }

    const vaultContract = new ethers.Contract(SOURCE_VAULT_ADDRESS, VAULT_ABI, wallet);

    console.log(chalk.blue(`📡 Ağ Bağlantısı: `) + "Localhost (Anvil)");
    console.log(chalk.blue(`💼 Cüzdan: `) + wallet.address);
    console.log(chalk.blue(`🏦 İzlenen Vault: `) + SOURCE_VAULT_ADDRESS);
    console.log(chalk.gray("------------------------------------------------"));

    // Sonsuz Döngü (Her 3 saniyede bir kontrol)
    setInterval(async () => {
        await checkYieldsAndAct(vaultContract);
    }, 3000);
}

// --- YAPAY ZEKA MANTIĞI ---
async function checkYieldsAndAct(contract) {
    // 1. Faiz oranlarını "Simüle Et" (Gerçek API demo sırasında risklidir)
    // Rastgele sayılar üreterek piyasayı taklit ediyoruz
    const optimismAPY = (Math.random() * (4.5 - 3.5) + 3.5).toFixed(2); // %3.5 - %4.5 arası
    const arbitrumAPY = (Math.random() * (7.0 - 2.0) + 2.0).toFixed(2); // %2.0 - %7.0 arası (Daha oynak)

    const timestamp = new Date().toLocaleTimeString();

    // 2. Terminale havalı loglar bas
    process.stdout.write(`\r[${timestamp}] 📊 Optimism: %${optimismAPY} | Arbitrum: %${arbitrumAPY} `);

    // 3. KARAR MEKANİZMASI
    // Eğer Arbitrum, Optimism'den %1.5 daha fazlaysa TAŞI!
    if (parseFloat(arbitrumAPY) > parseFloat(optimismAPY) + 1.5) {
        console.log("\n");
        console.log(chalk.yellow.bold("⚠️  FIRSAT TESPİT EDİLDİ! ⚠️"));
        console.log(chalk.green(`   Arbitrum (%${arbitrumAPY}) > Optimism (%${optimismAPY})`));
        console.log(chalk.cyan("🚀 Varlıklar taşınıyor... (Chainlink CCIP Devrede)"));

        try {
            // Kontratı Tetikle
            // Parametreler: (ChainID, HedefAdres, Miktar) - Demo için sabit değerler
            const tx = await contract.bridgeToStrategy(
                "999", // Hedef Chain ID (Mock)
                "0x0000000000000000000000000000000000000000", // Hedef Adapter (Mock)
                ethers.parseEther("10") // 10 USDC taşı
            );
            
            console.log(chalk.gray(`   Tx Hash: ${tx.hash}`));
            await tx.wait();
            console.log(chalk.green.bold("✅ TAŞIMA BAŞARILI! Paran artık %" + arbitrumAPY + " kazanıyor."));
            console.log(chalk.gray("------------------------------------------------"));
            
            // Heyecan yaratmak için 5 saniye bekle
            await new Promise(r => setTimeout(r, 5000));
            
        } catch (error) {
            console.log(chalk.red("❌ HATA OLUŞTU:"), error.message);
        }
    }
}

main();