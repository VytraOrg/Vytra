import { Injectable } from '@nestjs/common';

@Injectable()
export class SynonymsService {
  private synonymGroups: string[][] = [
    // Vegetables & Produce
    ['potato', 'aloo', 'alu', 'potatoes', 'batata'],
    ['onion', 'pyaz', 'kanda', 'piyaj', 'onions'],
    ['tomato', 'tamatar', 'tomatoes', 'bilati'],
    ['garlic', 'lehsun', 'losun', 'lasun'],
    ['ginger', 'adrak', 'ada'],
    ['chilli', 'mirch', 'morich', 'chili', 'chilies', 'green chilli'],
    ['lemon', 'nimbu', 'lebu', 'lime'],
    ['coriander', 'dhaniya', 'dhania', 'cilantro'],
    ['spinach', 'palak', 'paalok'],
    ['cucumber', 'kheera', 'shosha', 'kakdi'],
    ['carrot', 'gajar', 'gaajor'],
    ['peas', 'matar', 'motor'],
    ['cauliflower', 'gobhi', 'gobi', 'fulkopi'],
    ['cabbage', 'patta gobhi', 'bandhakopi'],

    // Dairy
    ['milk', 'doodh', 'dudh', 'taaza', 'toned'],
    ['butter', 'makkhan', 'makhan'],
    ['paneer', 'cottage cheese', 'panir', 'cheese'],
    ['curd', 'dahi', 'yogurt', 'yoghurt'],
    ['ghee', 'clarified butter', 'desi ghee'],

    // Staples & Grains
    ['rice', 'chawal', 'bhaat', 'basmati', 'kolam', 'gobindobhog'],
    ['wheat', 'gehun', 'gom'],
    ['flour', 'atta', 'aata', 'maida', 'besan', 'sooji', 'suji', 'rawa'],
    ['sugar', 'cheeni', 'chini', 'shukor', 'gur', 'jaggery'],
    ['salt', 'namak', 'noon', 'nun', 'sendha namak'],
    ['oil', 'tel', 'mustard oil', 'sunflower oil', 'refined oil', 'sarson'],
    ['dal', 'daal', 'pulses', 'lentils', 'moong', 'masoor', 'toor', 'chana', 'urad'],

    // Beverages & Tea
    ['tea', 'chai', 'cha', 'tea powder', 'tea leaves', 'green tea'],
    ['coffee', 'kafi', 'nescafe', 'bru'],

    // Snacks & Packaged Foods
    ['biscuit', 'biskit', 'cookies', 'biscot', 'rusk'],
    ['chips', 'wafers', 'crisps', 'kurkure', 'lays'],
    ['noodles', 'maggi', 'magi', 'chowmein', 'yippee', 'ramen'],
    ['chocolate', 'choclate', 'cadbury', 'choco', 'candy', 'toffee'],

    // Personal & Household
    ['soap', 'sabun', 'bathing bar', 'body wash'],
    ['detergent', 'washing powder', 'surf', 'rin', 'tide', 'ariel'],
    ['shampoo', 'hair wash', 'conditioner'],
    ['toothpaste', 'colgate', 'pepsodent', 'dant kanti', 'brush'],
  ];

  private synonymMap = new Map<string, Set<string>>();

  constructor() {
    this.initMap();
  }

  private initMap() {
    for (const group of this.synonymGroups) {
      const set = new Set(group.map((w) => w.toLowerCase()));
      for (const word of group) {
        this.synonymMap.set(word.toLowerCase(), set);
      }
    }
  }

  /**
   * Returns a list of synonyms for a given word/phrase, including the word itself.
   */
  getSynonyms(word: string): string[] {
    const lower = word.toLowerCase().trim();
    const matches = this.synonymMap.get(lower);
    if (matches) {
      return Array.from(matches);
    }
    return [lower];
  }

  /**
   * Expands an array of search query tokens to include their synonyms.
   */
  expandTokens(tokens: string[]): string[][] {
    return tokens.map((token) => this.getSynonyms(token));
  }
}
