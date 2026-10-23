import Foundation

/// The words Sample data fills the app with: plain, US, no city, nothing about him.
enum SampleText {
    static let notes = [
        "Sleep is training too\nSeven and a half hours most nights this week, and the bar moved faster.",
        "@Bench Press felt heavy on the third set\nMaybe the grip. Try a touch narrower on Thursday.",
        "Apartment\nAsk the office about the dishwasher and the parking spot renewal.",
        "Weekend\nFarmers market Saturday morning, then the long walk by the water.",
    ]

    static let recipes = [
        """
        French toast
        Serves 2
        Total time: 15 min
        3 eggs
        1/2 cup milk
        4 slices sourdough
        1 banana, sliced

        Whisk the eggs and milk.
        Soak the bread a minute a side, then cook in a hot pan until golden.
        Serve with the banana.
        """,
        """
        Sheet-pan chicken and vegetables
        Serves 4
        Total time: 40 min
        Ingredients
        1.5 lb chicken thighs
        2 cups broccoli florets
        1 red onion, cut in wedges
        2 tbsp olive oil
        1 tsp smoked paprika
        Salt and pepper, to taste
        Method
        Heat the oven to 425°F.
        Toss everything with the oil, paprika, salt and pepper on a sheet pan.
        Roast for 30 to 35 minutes, turning once, until the chicken is cooked through.
        """,
        """
        Black bean tacos
        Serves 2
        Ingredients
        1 can black beans, drained
        6 corn tortillas
        1 avocado
        1 lime
        1/2 cup salsa
        a handful of cilantro
        Method
        Warm the beans with a pinch of salt and a splash of water.
        Warm the tortillas in a dry pan.
        Fill with beans, sliced avocado, salsa and cilantro, and squeeze lime over.
        """,
    ]

    static let groceries = ["milk", "eggs", "bananas", "sourdough", "paper towels", "coffee beans"]
}
