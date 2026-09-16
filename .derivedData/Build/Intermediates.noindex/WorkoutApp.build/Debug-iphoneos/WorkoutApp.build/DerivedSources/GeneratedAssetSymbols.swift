import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "clean" asset catalog image resource.
    static let clean = DeveloperToolsSupport.ImageResource(name: "clean", bundle: resourceBundle)

    /// The "clean-and-jerk" asset catalog image resource.
    static let cleanAndJerk = DeveloperToolsSupport.ImageResource(name: "clean-and-jerk", bundle: resourceBundle)

    /// The "exercise-ab-wheel" asset catalog image resource.
    static let exerciseAbWheel = DeveloperToolsSupport.ImageResource(name: "exercise-ab-wheel", bundle: resourceBundle)

    /// The "exercise-back-extension" asset catalog image resource.
    static let exerciseBackExtension = DeveloperToolsSupport.ImageResource(name: "exercise-back-extension", bundle: resourceBundle)

    /// The "exercise-back-squat" asset catalog image resource.
    static let exerciseBackSquat = DeveloperToolsSupport.ImageResource(name: "exercise-back-squat", bundle: resourceBundle)

    /// The "exercise-barbell-bench-press" asset catalog image resource.
    static let exerciseBarbellBenchPress = DeveloperToolsSupport.ImageResource(name: "exercise-barbell-bench-press", bundle: resourceBundle)

    /// The "exercise-barbell-curl" asset catalog image resource.
    static let exerciseBarbellCurl = DeveloperToolsSupport.ImageResource(name: "exercise-barbell-curl", bundle: resourceBundle)

    /// The "exercise-barbell-hip-thrust" asset catalog image resource.
    static let exerciseBarbellHipThrust = DeveloperToolsSupport.ImageResource(name: "exercise-barbell-hip-thrust", bundle: resourceBundle)

    /// The "exercise-barbell-row" asset catalog image resource.
    static let exerciseBarbellRow = DeveloperToolsSupport.ImageResource(name: "exercise-barbell-row", bundle: resourceBundle)

    /// The "exercise-barbell-shrug" asset catalog image resource.
    static let exerciseBarbellShrug = DeveloperToolsSupport.ImageResource(name: "exercise-barbell-shrug", bundle: resourceBundle)

    /// The "exercise-belt-squat" asset catalog image resource.
    static let exerciseBeltSquat = DeveloperToolsSupport.ImageResource(name: "exercise-belt-squat", bundle: resourceBundle)

    /// The "exercise-box-jump" asset catalog image resource.
    static let exerciseBoxJump = DeveloperToolsSupport.ImageResource(name: "exercise-box-jump", bundle: resourceBundle)

    /// The "exercise-bulgarian-split-squat" asset catalog image resource.
    static let exerciseBulgarianSplitSquat = DeveloperToolsSupport.ImageResource(name: "exercise-bulgarian-split-squat", bundle: resourceBundle)

    /// The "exercise-cable-crunch" asset catalog image resource.
    static let exerciseCableCrunch = DeveloperToolsSupport.ImageResource(name: "exercise-cable-crunch", bundle: resourceBundle)

    /// The "exercise-cable-curl" asset catalog image resource.
    static let exerciseCableCurl = DeveloperToolsSupport.ImageResource(name: "exercise-cable-curl", bundle: resourceBundle)

    /// The "exercise-cable-fly" asset catalog image resource.
    static let exerciseCableFly = DeveloperToolsSupport.ImageResource(name: "exercise-cable-fly", bundle: resourceBundle)

    /// The "exercise-cable-lateral-raise" asset catalog image resource.
    static let exerciseCableLateralRaise = DeveloperToolsSupport.ImageResource(name: "exercise-cable-lateral-raise", bundle: resourceBundle)

    /// The "exercise-cable-woodchop" asset catalog image resource.
    static let exerciseCableWoodchop = DeveloperToolsSupport.ImageResource(name: "exercise-cable-woodchop", bundle: resourceBundle)

    /// The "exercise-calf-raise" asset catalog image resource.
    static let exerciseCalfRaise = DeveloperToolsSupport.ImageResource(name: "exercise-calf-raise", bundle: resourceBundle)

    /// The "exercise-chest-supported-dumbbell-row" asset catalog image resource.
    static let exerciseChestSupportedDumbbellRow = DeveloperToolsSupport.ImageResource(name: "exercise-chest-supported-dumbbell-row", bundle: resourceBundle)

    /// The "exercise-chest-supported-t-bar-row" asset catalog image resource.
    static let exerciseChestSupportedTBarRow = DeveloperToolsSupport.ImageResource(name: "exercise-chest-supported-t-bar-row", bundle: resourceBundle)

    /// The "exercise-chin-up" asset catalog image resource.
    static let exerciseChinUp = DeveloperToolsSupport.ImageResource(name: "exercise-chin-up", bundle: resourceBundle)

    /// The "exercise-close-grip-bench-press" asset catalog image resource.
    static let exerciseCloseGripBenchPress = DeveloperToolsSupport.ImageResource(name: "exercise-close-grip-bench-press", bundle: resourceBundle)

    /// The "exercise-close-grip-lat-pulldown" asset catalog image resource.
    static let exerciseCloseGripLatPulldown = DeveloperToolsSupport.ImageResource(name: "exercise-close-grip-lat-pulldown", bundle: resourceBundle)

    /// The "exercise-concentration-curl" asset catalog image resource.
    static let exerciseConcentrationCurl = DeveloperToolsSupport.ImageResource(name: "exercise-concentration-curl", bundle: resourceBundle)

    /// The "exercise-deadlift" asset catalog image resource.
    static let exerciseDeadlift = DeveloperToolsSupport.ImageResource(name: "exercise-deadlift", bundle: resourceBundle)

    /// The "exercise-dips" asset catalog image resource.
    static let exerciseDips = DeveloperToolsSupport.ImageResource(name: "exercise-dips", bundle: resourceBundle)

    /// The "exercise-dumbbell-bench-press" asset catalog image resource.
    static let exerciseDumbbellBenchPress = DeveloperToolsSupport.ImageResource(name: "exercise-dumbbell-bench-press", bundle: resourceBundle)

    /// The "exercise-dumbbell-curl" asset catalog image resource.
    static let exerciseDumbbellCurl = DeveloperToolsSupport.ImageResource(name: "exercise-dumbbell-curl", bundle: resourceBundle)

    /// The "exercise-dumbbell-fly" asset catalog image resource.
    static let exerciseDumbbellFly = DeveloperToolsSupport.ImageResource(name: "exercise-dumbbell-fly", bundle: resourceBundle)

    /// The "exercise-dumbbell-shoulder-press" asset catalog image resource.
    static let exerciseDumbbellShoulderPress = DeveloperToolsSupport.ImageResource(name: "exercise-dumbbell-shoulder-press", bundle: resourceBundle)

    /// The "exercise-dumbbell-shrug" asset catalog image resource.
    static let exerciseDumbbellShrug = DeveloperToolsSupport.ImageResource(name: "exercise-dumbbell-shrug", bundle: resourceBundle)

    /// The "exercise-face-pull" asset catalog image resource.
    static let exerciseFacePull = DeveloperToolsSupport.ImageResource(name: "exercise-face-pull", bundle: resourceBundle)

    /// The "exercise-farmers-walk" asset catalog image resource.
    static let exerciseFarmersWalk = DeveloperToolsSupport.ImageResource(name: "exercise-farmers-walk", bundle: resourceBundle)

    /// The "exercise-forward-lunge" asset catalog image resource.
    static let exerciseForwardLunge = DeveloperToolsSupport.ImageResource(name: "exercise-forward-lunge", bundle: resourceBundle)

    /// The "exercise-front-raise" asset catalog image resource.
    static let exerciseFrontRaise = DeveloperToolsSupport.ImageResource(name: "exercise-front-raise", bundle: resourceBundle)

    /// The "exercise-front-squat" asset catalog image resource.
    static let exerciseFrontSquat = DeveloperToolsSupport.ImageResource(name: "exercise-front-squat", bundle: resourceBundle)

    /// The "exercise-glute-ham-raise" asset catalog image resource.
    static let exerciseGluteHamRaise = DeveloperToolsSupport.ImageResource(name: "exercise-glute-ham-raise", bundle: resourceBundle)

    /// The "exercise-glute-kickback" asset catalog image resource.
    static let exerciseGluteKickback = DeveloperToolsSupport.ImageResource(name: "exercise-glute-kickback", bundle: resourceBundle)

    /// The "exercise-good-morning" asset catalog image resource.
    static let exerciseGoodMorning = DeveloperToolsSupport.ImageResource(name: "exercise-good-morning", bundle: resourceBundle)

    /// The "exercise-hack-squat" asset catalog image resource.
    static let exerciseHackSquat = DeveloperToolsSupport.ImageResource(name: "exercise-hack-squat", bundle: resourceBundle)

    /// The "exercise-hammer-curl" asset catalog image resource.
    static let exerciseHammerCurl = DeveloperToolsSupport.ImageResource(name: "exercise-hammer-curl", bundle: resourceBundle)

    /// The "exercise-hanging-leg-raise" asset catalog image resource.
    static let exerciseHangingLegRaise = DeveloperToolsSupport.ImageResource(name: "exercise-hanging-leg-raise", bundle: resourceBundle)

    /// The "exercise-hip-thrust" asset catalog image resource.
    static let exerciseHipThrust = DeveloperToolsSupport.ImageResource(name: "exercise-hip-thrust", bundle: resourceBundle)

    /// The "exercise-incline-barbell-bench-press" asset catalog image resource.
    static let exerciseInclineBarbellBenchPress = DeveloperToolsSupport.ImageResource(name: "exercise-incline-barbell-bench-press", bundle: resourceBundle)

    /// The "exercise-incline-dumbbell-curl" asset catalog image resource.
    static let exerciseInclineDumbbellCurl = DeveloperToolsSupport.ImageResource(name: "exercise-incline-dumbbell-curl", bundle: resourceBundle)

    /// The "exercise-incline-dumbbell-press" asset catalog image resource.
    static let exerciseInclineDumbbellPress = DeveloperToolsSupport.ImageResource(name: "exercise-incline-dumbbell-press", bundle: resourceBundle)

    /// The "exercise-jefferson-curl" asset catalog image resource.
    static let exerciseJeffersonCurl = DeveloperToolsSupport.ImageResource(name: "exercise-jefferson-curl", bundle: resourceBundle)

    /// The "exercise-kettlebell-clean" asset catalog image resource.
    static let exerciseKettlebellClean = DeveloperToolsSupport.ImageResource(name: "exercise-kettlebell-clean", bundle: resourceBundle)

    /// The "exercise-kettlebell-clean-and-jerk" asset catalog image resource.
    static let exerciseKettlebellCleanAndJerk = DeveloperToolsSupport.ImageResource(name: "exercise-kettlebell-clean-and-jerk", bundle: resourceBundle)

    /// The "exercise-kettlebell-snatch" asset catalog image resource.
    static let exerciseKettlebellSnatch = DeveloperToolsSupport.ImageResource(name: "exercise-kettlebell-snatch", bundle: resourceBundle)

    /// The "exercise-kettlebell-swing" asset catalog image resource.
    static let exerciseKettlebellSwing = DeveloperToolsSupport.ImageResource(name: "exercise-kettlebell-swing", bundle: resourceBundle)

    /// The "exercise-landmine-press" asset catalog image resource.
    static let exerciseLandminePress = DeveloperToolsSupport.ImageResource(name: "exercise-landmine-press", bundle: resourceBundle)

    /// The "exercise-landmine-rotation" asset catalog image resource.
    static let exerciseLandmineRotation = DeveloperToolsSupport.ImageResource(name: "exercise-landmine-rotation", bundle: resourceBundle)

    /// The "exercise-landmine-row" asset catalog image resource.
    static let exerciseLandmineRow = DeveloperToolsSupport.ImageResource(name: "exercise-landmine-row", bundle: resourceBundle)

    /// The "exercise-landmine-squat" asset catalog image resource.
    static let exerciseLandmineSquat = DeveloperToolsSupport.ImageResource(name: "exercise-landmine-squat", bundle: resourceBundle)

    /// The "exercise-lat-pulldown" asset catalog image resource.
    static let exerciseLatPulldown = DeveloperToolsSupport.ImageResource(name: "exercise-lat-pulldown", bundle: resourceBundle)

    /// The "exercise-lateral-raise" asset catalog image resource.
    static let exerciseLateralRaise = DeveloperToolsSupport.ImageResource(name: "exercise-lateral-raise", bundle: resourceBundle)

    /// The "exercise-leg-extension" asset catalog image resource.
    static let exerciseLegExtension = DeveloperToolsSupport.ImageResource(name: "exercise-leg-extension", bundle: resourceBundle)

    /// The "exercise-leg-press" asset catalog image resource.
    static let exerciseLegPress = DeveloperToolsSupport.ImageResource(name: "exercise-leg-press", bundle: resourceBundle)

    /// The "exercise-lying-leg-curl" asset catalog image resource.
    static let exerciseLyingLegCurl = DeveloperToolsSupport.ImageResource(name: "exercise-lying-leg-curl", bundle: resourceBundle)

    /// The "exercise-machine-chest-press" asset catalog image resource.
    static let exerciseMachineChestPress = DeveloperToolsSupport.ImageResource(name: "exercise-machine-chest-press", bundle: resourceBundle)

    /// The "exercise-machine-hip-abduction" asset catalog image resource.
    static let exerciseMachineHipAbduction = DeveloperToolsSupport.ImageResource(name: "exercise-machine-hip-abduction", bundle: resourceBundle)

    /// The "exercise-machine-hip-adduction" asset catalog image resource.
    static let exerciseMachineHipAdduction = DeveloperToolsSupport.ImageResource(name: "exercise-machine-hip-adduction", bundle: resourceBundle)

    /// The "exercise-nordic-curl" asset catalog image resource.
    static let exerciseNordicCurl = DeveloperToolsSupport.ImageResource(name: "exercise-nordic-curl", bundle: resourceBundle)

    /// The "exercise-one-arm-cable-row" asset catalog image resource.
    static let exerciseOneArmCableRow = DeveloperToolsSupport.ImageResource(name: "exercise-one-arm-cable-row", bundle: resourceBundle)

    /// The "exercise-one-arm-dumbbell-row" asset catalog image resource.
    static let exerciseOneArmDumbbellRow = DeveloperToolsSupport.ImageResource(name: "exercise-one-arm-dumbbell-row", bundle: resourceBundle)

    /// The "exercise-overhead-cable-triceps-extension" asset catalog image resource.
    static let exerciseOverheadCableTricepsExtension = DeveloperToolsSupport.ImageResource(name: "exercise-overhead-cable-triceps-extension", bundle: resourceBundle)

    /// The "exercise-overhead-press" asset catalog image resource.
    static let exerciseOverheadPress = DeveloperToolsSupport.ImageResource(name: "exercise-overhead-press", bundle: resourceBundle)

    /// The "exercise-pec-deck" asset catalog image resource.
    static let exercisePecDeck = DeveloperToolsSupport.ImageResource(name: "exercise-pec-deck", bundle: resourceBundle)

    /// The "exercise-plank" asset catalog image resource.
    static let exercisePlank = DeveloperToolsSupport.ImageResource(name: "exercise-plank", bundle: resourceBundle)

    /// The "exercise-power-snatch" asset catalog image resource.
    static let exercisePowerSnatch = DeveloperToolsSupport.ImageResource(name: "exercise-power-snatch", bundle: resourceBundle)

    /// The "exercise-preacher-curl" asset catalog image resource.
    static let exercisePreacherCurl = DeveloperToolsSupport.ImageResource(name: "exercise-preacher-curl", bundle: resourceBundle)

    /// The "exercise-pull-up" asset catalog image resource.
    static let exercisePullUp = DeveloperToolsSupport.ImageResource(name: "exercise-pull-up", bundle: resourceBundle)

    /// The "exercise-push-up" asset catalog image resource.
    static let exercisePushUp = DeveloperToolsSupport.ImageResource(name: "exercise-push-up", bundle: resourceBundle)

    /// The "exercise-rear-delt-fly" asset catalog image resource.
    static let exerciseRearDeltFly = DeveloperToolsSupport.ImageResource(name: "exercise-rear-delt-fly", bundle: resourceBundle)

    /// The "exercise-reverse-curl" asset catalog image resource.
    static let exerciseReverseCurl = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-curl", bundle: resourceBundle)

    /// The "exercise-reverse-hyper" asset catalog image resource.
    static let exerciseReverseHyper = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-hyper", bundle: resourceBundle)

    /// The "exercise-reverse-lunge" asset catalog image resource.
    static let exerciseReverseLunge = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-lunge", bundle: resourceBundle)

    /// The "exercise-reverse-pec-deck" asset catalog image resource.
    static let exerciseReversePecDeck = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-pec-deck", bundle: resourceBundle)

    /// The "exercise-reverse-squat" asset catalog image resource.
    static let exerciseReverseSquat = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-squat", bundle: resourceBundle)

    /// The "exercise-reverse-wrist-curl" asset catalog image resource.
    static let exerciseReverseWristCurl = DeveloperToolsSupport.ImageResource(name: "exercise-reverse-wrist-curl", bundle: resourceBundle)

    /// The "exercise-romanian-deadlift" asset catalog image resource.
    static let exerciseRomanianDeadlift = DeveloperToolsSupport.ImageResource(name: "exercise-romanian-deadlift", bundle: resourceBundle)

    /// The "exercise-seated-cable-row" asset catalog image resource.
    static let exerciseSeatedCableRow = DeveloperToolsSupport.ImageResource(name: "exercise-seated-cable-row", bundle: resourceBundle)

    /// The "exercise-seated-good-morning" asset catalog image resource.
    static let exerciseSeatedGoodMorning = DeveloperToolsSupport.ImageResource(name: "exercise-seated-good-morning", bundle: resourceBundle)

    /// The "exercise-seated-leg-curl" asset catalog image resource.
    static let exerciseSeatedLegCurl = DeveloperToolsSupport.ImageResource(name: "exercise-seated-leg-curl", bundle: resourceBundle)

    /// The "exercise-sissy-squat" asset catalog image resource.
    static let exerciseSissySquat = DeveloperToolsSupport.ImageResource(name: "exercise-sissy-squat", bundle: resourceBundle)

    /// The "exercise-sit-up" asset catalog image resource.
    static let exerciseSitUp = DeveloperToolsSupport.ImageResource(name: "exercise-sit-up", bundle: resourceBundle)

    /// The "exercise-skull-crusher" asset catalog image resource.
    static let exerciseSkullCrusher = DeveloperToolsSupport.ImageResource(name: "exercise-skull-crusher", bundle: resourceBundle)

    /// The "exercise-smith-machine-squat" asset catalog image resource.
    static let exerciseSmithMachineSquat = DeveloperToolsSupport.ImageResource(name: "exercise-smith-machine-squat", bundle: resourceBundle)

    /// The "exercise-snatch" asset catalog image resource.
    static let exerciseSnatch = DeveloperToolsSupport.ImageResource(name: "exercise-snatch", bundle: resourceBundle)

    /// The "exercise-spider-curl" asset catalog image resource.
    static let exerciseSpiderCurl = DeveloperToolsSupport.ImageResource(name: "exercise-spider-curl", bundle: resourceBundle)

    /// The "exercise-step-up" asset catalog image resource.
    static let exerciseStepUp = DeveloperToolsSupport.ImageResource(name: "exercise-step-up", bundle: resourceBundle)

    /// The "exercise-tibialis-raise" asset catalog image resource.
    static let exerciseTibialisRaise = DeveloperToolsSupport.ImageResource(name: "exercise-tibialis-raise", bundle: resourceBundle)

    /// The "exercise-tricep-pushdown" asset catalog image resource.
    static let exerciseTricepPushdown = DeveloperToolsSupport.ImageResource(name: "exercise-tricep-pushdown", bundle: resourceBundle)

    /// The "exercise-upright-row" asset catalog image resource.
    static let exerciseUprightRow = DeveloperToolsSupport.ImageResource(name: "exercise-upright-row", bundle: resourceBundle)

    /// The "exercise-walking-lunge" asset catalog image resource.
    static let exerciseWalkingLunge = DeveloperToolsSupport.ImageResource(name: "exercise-walking-lunge", bundle: resourceBundle)

    /// The "exercise-wide-grip-lat-pulldown" asset catalog image resource.
    static let exerciseWideGripLatPulldown = DeveloperToolsSupport.ImageResource(name: "exercise-wide-grip-lat-pulldown", bundle: resourceBundle)

    /// The "exercise-wrist-curl" asset catalog image resource.
    static let exerciseWristCurl = DeveloperToolsSupport.ImageResource(name: "exercise-wrist-curl", bundle: resourceBundle)

    /// The "exercise-zercher-carry" asset catalog image resource.
    static let exerciseZercherCarry = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-carry", bundle: resourceBundle)

    /// The "exercise-zercher-deadlift" asset catalog image resource.
    static let exerciseZercherDeadlift = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-deadlift", bundle: resourceBundle)

    /// The "exercise-zercher-jefferson-curl" asset catalog image resource.
    static let exerciseZercherJeffersonCurl = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-jefferson-curl", bundle: resourceBundle)

    /// The "exercise-zercher-lunge" asset catalog image resource.
    static let exerciseZercherLunge = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-lunge", bundle: resourceBundle)

    /// The "exercise-zercher-reverse-lunge" asset catalog image resource.
    static let exerciseZercherReverseLunge = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-reverse-lunge", bundle: resourceBundle)

    /// The "exercise-zercher-split-squat" asset catalog image resource.
    static let exerciseZercherSplitSquat = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-split-squat", bundle: resourceBundle)

    /// The "exercise-zercher-squat" asset catalog image resource.
    static let exerciseZercherSquat = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-squat", bundle: resourceBundle)

    /// The "exercise-zercher-step-up" asset catalog image resource.
    static let exerciseZercherStepUp = DeveloperToolsSupport.ImageResource(name: "exercise-zercher-step-up", bundle: resourceBundle)

    /// The "guide-abductors" asset catalog image resource.
    static let guideAbductors = DeveloperToolsSupport.ImageResource(name: "guide-abductors", bundle: resourceBundle)

    /// The "guide-adductors" asset catalog image resource.
    static let guideAdductors = DeveloperToolsSupport.ImageResource(name: "guide-adductors", bundle: resourceBundle)

    /// The "guide-anterior-delts" asset catalog image resource.
    static let guideAnteriorDelts = DeveloperToolsSupport.ImageResource(name: "guide-anterior-delts", bundle: resourceBundle)

    /// The "guide-biceps" asset catalog image resource.
    static let guideBiceps = DeveloperToolsSupport.ImageResource(name: "guide-biceps", bundle: resourceBundle)

    /// The "guide-calves" asset catalog image resource.
    static let guideCalves = DeveloperToolsSupport.ImageResource(name: "guide-calves", bundle: resourceBundle)

    /// The "guide-chest-pectorals" asset catalog image resource.
    static let guideChestPectorals = DeveloperToolsSupport.ImageResource(name: "guide-chest-pectorals", bundle: resourceBundle)

    /// The "guide-core-abs" asset catalog image resource.
    static let guideCoreAbs = DeveloperToolsSupport.ImageResource(name: "guide-core-abs", bundle: resourceBundle)

    /// The "guide-erectors" asset catalog image resource.
    static let guideErectors = DeveloperToolsSupport.ImageResource(name: "guide-erectors", bundle: resourceBundle)

    /// The "guide-forearms-grip" asset catalog image resource.
    static let guideForearmsGrip = DeveloperToolsSupport.ImageResource(name: "guide-forearms-grip", bundle: resourceBundle)

    /// The "guide-glutes" asset catalog image resource.
    static let guideGlutes = DeveloperToolsSupport.ImageResource(name: "guide-glutes", bundle: resourceBundle)

    /// The "guide-hamstrings" asset catalog image resource.
    static let guideHamstrings = DeveloperToolsSupport.ImageResource(name: "guide-hamstrings", bundle: resourceBundle)

    /// The "guide-hip-flexors" asset catalog image resource.
    static let guideHipFlexors = DeveloperToolsSupport.ImageResource(name: "guide-hip-flexors", bundle: resourceBundle)

    /// The "guide-lateral-delts" asset catalog image resource.
    static let guideLateralDelts = DeveloperToolsSupport.ImageResource(name: "guide-lateral-delts", bundle: resourceBundle)

    /// The "guide-lats" asset catalog image resource.
    static let guideLats = DeveloperToolsSupport.ImageResource(name: "guide-lats", bundle: resourceBundle)

    /// The "guide-posterior-delts" asset catalog image resource.
    static let guidePosteriorDelts = DeveloperToolsSupport.ImageResource(name: "guide-posterior-delts", bundle: resourceBundle)

    /// The "guide-pulls" asset catalog image resource.
    static let guidePulls = DeveloperToolsSupport.ImageResource(name: "guide-pulls", bundle: resourceBundle)

    /// The "guide-pushes" asset catalog image resource.
    static let guidePushes = DeveloperToolsSupport.ImageResource(name: "guide-pushes", bundle: resourceBundle)

    /// The "guide-quadriceps" asset catalog image resource.
    static let guideQuadriceps = DeveloperToolsSupport.ImageResource(name: "guide-quadriceps", bundle: resourceBundle)

    /// The "guide-rhomboids" asset catalog image resource.
    static let guideRhomboids = DeveloperToolsSupport.ImageResource(name: "guide-rhomboids", bundle: resourceBundle)

    /// The "guide-squat-pattern" asset catalog image resource.
    static let guideSquatPattern = DeveloperToolsSupport.ImageResource(name: "guide-squat-pattern", bundle: resourceBundle)

    /// The "guide-tibialis" asset catalog image resource.
    static let guideTibialis = DeveloperToolsSupport.ImageResource(name: "guide-tibialis", bundle: resourceBundle)

    /// The "guide-traps" asset catalog image resource.
    static let guideTraps = DeveloperToolsSupport.ImageResource(name: "guide-traps", bundle: resourceBundle)

    /// The "guide-triceps" asset catalog image resource.
    static let guideTriceps = DeveloperToolsSupport.ImageResource(name: "guide-triceps", bundle: resourceBundle)

}

