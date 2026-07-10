# Verify bundled game content without invoking Flutter.

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir

function Read-JsonArray {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing content file: $Path"
    }

    $items = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $items -or $items.Count -eq 0) {
        throw "Content file is empty: $Path"
    }
    return $items
}

function Test-RequiredString {
    param(
        [object]$Item,
        [string]$Field,
        [string]$Context
    )

    $value = $Item.$Field
    if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
        throw "$Context is missing $Field."
    }
}

$questions = Read-JsonArray "assets/data/questions.json"
$cards = Read-JsonArray "assets/data/cards.json"
$enemies = Read-JsonArray "assets/data/enemies.json"
$allowedCategories = @{
    "nature_geography" = $true
    "living_things" = $true
    "history" = $true
    "science" = $true
    "food" = $true
    "language" = $true
    "daily_life" = $true
}
$requiredAudioAssets = @(
    "assets/audio/bgm_dungeon_loop.wav",
    "assets/audio/se_select.wav",
    "assets/audio/se_correct.wav",
    "assets/audio/se_wrong.wav",
    "assets/audio/se_hit.wav",
    "assets/audio/se_enemy_down.wav",
    "assets/audio/se_floor_clear.wav",
    "assets/audio/se_reward.wav"
)
$requiredImageAssets = @(
    "assets/images/backgrounds/battle_stage.png",
    "assets/images/backgrounds/home_dungeon.png",
    "assets/images/characters/player.png",
    "assets/images/effects/defeat_smoke.png",
    "assets/images/effects/hit_spark.png",
    "assets/images/effects/slash.png",
    "assets/images/effects/stamp_correct.png",
    "assets/images/effects/stamp_wrong.png",
    "assets/images/ui/treasure_chest.png"
)

function Test-AssetFiles {
    param(
        [string[]]$Paths,
        [string]$Kind
    )

    foreach ($assetPath in $Paths) {
        if (-not (Test-Path -LiteralPath $assetPath)) {
            throw "Missing $Kind asset: $assetPath"
        }
        $assetFile = Get-Item -LiteralPath $assetPath
        if ($assetFile.Length -le 0) {
            throw "$Kind asset is empty: $assetPath"
        }
    }
}

Test-AssetFiles $requiredAudioAssets "audio"
Test-AssetFiles $requiredImageAssets "image"

$cardIds = @{}
$cardCategories = @{}
foreach ($card in $cards) {
    Test-RequiredString $card "id" "card"
    Test-RequiredString $card "title" "card $($card.id)"
    Test-RequiredString $card "category" "card $($card.id)"
    Test-RequiredString $card "shortText" "card $($card.id)"
    Test-RequiredString $card "detailText" "card $($card.id)"
    if (-not $allowedCategories.ContainsKey($card.category)) {
        throw "Card $($card.id) has unknown category $($card.category)."
    }
    if ($card.imageAsset) {
        if (-not (Test-Path -LiteralPath $card.imageAsset)) {
            throw "Card $($card.id) references missing image $($card.imageAsset)."
        }
        $cardImage = Get-Item -LiteralPath $card.imageAsset
        if ($cardImage.Length -le 0) {
            throw "Card $($card.id) references empty image $($card.imageAsset)."
        }
    }
    if ($cardIds.ContainsKey($card.id)) {
        throw "Duplicate card id: $($card.id)"
    }
    $cardIds[$card.id] = $true
    $cardCategories[$card.id] = $card.category
}

$questionIds = @{}
foreach ($question in $questions) {
    Test-RequiredString $question "id" "question"
    if ($questionIds.ContainsKey($question.id)) {
        throw "Duplicate question id: $($question.id)"
    }
    $questionIds[$question.id] = $true
    Test-RequiredString $question "question" "question $($question.id)"
    Test-RequiredString $question "category" "question $($question.id)"
    Test-RequiredString $question "relatedCardId" "question $($question.id)"
    if (-not $allowedCategories.ContainsKey($question.category)) {
        throw "Question $($question.id) has unknown category $($question.category)."
    }
    if (-not $cardIds.ContainsKey($question.relatedCardId)) {
        throw "Question $($question.id) references missing card $($question.relatedCardId)."
    }
    if ($cardCategories[$question.relatedCardId] -ne $question.category) {
        throw "Question $($question.id) category $($question.category) does not match card $($question.relatedCardId) category $($cardCategories[$question.relatedCardId])."
    }
    if ($question.choices.Count -ne 4) {
        throw "Question $($question.id) must have exactly 4 choices."
    }
    $choiceSet = @{}
    foreach ($choice in $question.choices) {
        if ([string]::IsNullOrWhiteSpace([string]$choice)) {
            throw "Question $($question.id) has an empty choice."
        }
        if ($choiceSet.ContainsKey($choice)) {
            throw "Question $($question.id) has duplicate choice: $choice"
        }
        $choiceSet[$choice] = $true
    }
    if ($question.answerIndex -lt 0 -or $question.answerIndex -gt 3) {
        throw "Question $($question.id) has invalid answerIndex $($question.answerIndex)."
    }
}

$normalEnemies = @($enemies | Where-Object { $_.type -eq "normal" })
$bossEnemies = @($enemies | Where-Object { $_.type -eq "boss" })
if ($normalEnemies.Count -lt 4) {
    throw "Expected at least 4 normal enemies, found $($normalEnemies.Count)."
}
if ($bossEnemies.Count -lt 1) {
    throw "Expected at least 1 boss enemy, found $($bossEnemies.Count)."
}

$enemyIds = @{}
foreach ($enemy in $enemies) {
    Test-RequiredString $enemy "id" "enemy"
    if ($enemyIds.ContainsKey($enemy.id)) {
        throw "Duplicate enemy id: $($enemy.id)"
    }
    $enemyIds[$enemy.id] = $true
    Test-RequiredString $enemy "name" "enemy $($enemy.id)"
    Test-RequiredString $enemy "type" "enemy $($enemy.id)"
    if ($null -eq $enemy.maxHp -or $enemy.maxHp -le 0) {
        throw "Enemy $($enemy.id) has invalid maxHp $($enemy.maxHp)."
    }
    if ($null -eq $enemy.attack -or $enemy.attack -le 0) {
        throw "Enemy $($enemy.id) has invalid attack $($enemy.attack)."
    }
    if ($enemy.imageAsset -and -not (Test-Path -LiteralPath $enemy.imageAsset)) {
        throw "Enemy $($enemy.id) references missing image $($enemy.imageAsset)."
    }
}

Write-Host "Content verification passed: $($questions.Count) questions, $($cards.Count) cards, $($enemies.Count) enemies, $($requiredAudioAssets.Count) audio assets, $($requiredImageAssets.Count) image assets." -ForegroundColor Green
