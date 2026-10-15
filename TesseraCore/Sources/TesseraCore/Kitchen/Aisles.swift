import Foundation

/// Where things are in a shop (kitchen slice 7), in walking order. An ingredient's aisle is learned: the guide
/// below is the starting point, and moving an item on the groceries list teaches its ingredient.
public enum Aisle: String, CaseIterable, Sendable {
    case produce = "Produce", bakery = "Bakery", meatFish = "Meat and fish", dairy = "Dairy"
    case dryGoods = "Dry goods", tinsJars = "Tins and jars", spices = "Spices", frozen = "Frozen"
    case household = "Household", other = "Other"

    /// The order a shop is walked in; unknown section names go last.
    public static func order(of name: String?) -> Int {
        name.flatMap { Aisle(rawValue: $0) }.flatMap { allCases.firstIndex(of: $0) } ?? allCases.count
    }
}

/// ~150 common ingredients with their aisle, and the staples that are skipped when a recipe goes on the list.
public enum AisleGuide {
    public static let staples: Set<String> = [
        "salt", "black pepper", "olive oil", "vegetable oil", "oil", "water", "sea salt",
    ]

    public static func aisle(for name: String) -> Aisle? {
        let key = IngredientLine.key(for: name)
        if let aisle = guide[key] {
            return aisle
        }
        // "red onion" → onion, "smoked paprika" → paprika: try the last word, then the last two.
        let words = key.split(separator: " ")
        if words.count > 1 {
            if let aisle = guide[words.suffix(2).joined(separator: " ")] {
                return aisle
            }
            if let last = words.last, let aisle = guide[String(last)] {
                return aisle
            }
        }
        return nil
    }

    static let guide: [String: Aisle] = {
        var map: [String: Aisle] = [:]
        func add(_ aisle: Aisle, _ names: String) {
            for name in names.split(separator: ",") {
                map[IngredientLine.key(for: name.trimmingCharacters(in: .whitespaces))] = aisle
            }
        }
        add(.produce, """
        onion, garlic, ginger, shallot, spring onion, leek, carrot, celery, potato, sweet potato, tomato, \
        cherry tomato, cucumber, courgette, zucchini, aubergine, eggplant, pepper, bell pepper, chilli, chili, \
        lettuce, spinach, rocket, kale, cabbage, broccoli, cauliflower, mushroom, pea, green bean, sweetcorn, \
        avocado, lemon, lime, orange, apple, banana, pear, grape, strawberry, blueberry, raspberry, mango, \
        pineapple, basil, parsley, coriander, cilantro, mint, dill, thyme, rosemary, sage, chive, bay leaf, \
        beetroot, radish, fennel, asparagus, pak choi, butternut squash, pumpkin, squash
        """)
        add(.bakery, "bread, baguette, sourdough, pitta, pita, tortilla, wrap, naan, bun, roll, bagel, croissant")
        add(.meatFish, """
        chicken, chicken breast, chicken thigh, beef, mince, beef mince, steak, pork, bacon, guanciale, pancetta, \
        sausage, chorizo, ham, lamb, turkey, duck, salmon, cod, tuna steak, prawn, shrimp, mussel, haddock, \
        sea bass, mackerel
        """)
        add(.dairy, """
        milk, butter, cream, double cream, single cream, soured cream, sour cream, creme fraiche, yogurt, yoghurt, \
        greek yogurt, cheese, cheddar, parmesan, pecorino, mozzarella, feta, halloumi, ricotta, mascarpone, \
        cream cheese, egg, oat milk
        """)
        add(.dryGoods, """
        flour, plain flour, self-raising flour, bread flour, sugar, caster sugar, brown sugar, icing sugar, rice, \
        basmati rice, risotto rice, pasta, spaghetti, penne, linguine, fusilli, lasagne, noodle, egg noodle, \
        oat, couscous, quinoa, bulgur, lentil, red lentil, breadcrumb, panko, yeast, baking powder, \
        bicarbonate of soda, baking soda, cornflour, cocoa, chocolate, dark chocolate, honey, maple syrup, \
        nut, almond, walnut, peanut, cashew, pine nut, raisin, stock cube, cereal
        """)
        add(.tinsJars, """
        chopped tomato, tinned tomato, passata, tomato puree, tomato paste, coconut milk, chickpea, kidney bean, \
        black bean, cannellini bean, baked bean, tuna, sweetcorn tin, olive, caper, anchovy, pesto, jam, \
        peanut butter, mustard, dijon mustard, mayonnaise, ketchup, soy sauce, fish sauce, \
        worcestershire sauce, vinegar, balsamic vinegar, red wine vinegar, olive oil, vegetable oil, oil, \
        sesame oil, stock, tahini, curry paste
        """)
        add(.spices, """
        salt, sea salt, black pepper, paprika, smoked paprika, cumin, ground cumin, coriander seed, turmeric, \
        chilli flake, chili flake, cayenne, garam masala, curry powder, cinnamon, nutmeg, oregano, \
        dried oregano, mixed herb, clove spice, cardamom, star anise, vanilla, vanilla extract, fennel seed, \
        mustard seed, saffron
        """)
        add(.frozen, "frozen pea, frozen spinach, ice cream, frozen berry, frozen prawn, ice")
        add(.household, """
        kitchen roll, washing up liquid, bin bag, foil, cling film, baking paper, toilet roll, dishwasher tablet, \
        sponge, toothpaste, shampoo, soap, deodorant, razor
        """)
        return map
    }()
}
