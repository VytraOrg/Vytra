import { Injectable } from '@nestjs/common';

@Injectable()
export class SpellcheckService {
  private vocabulary = new Set<string>([
    // Common Grocery & Supermarket terms
    'potato', 'potatoes', 'onion', 'onions', 'tomato', 'tomatoes', 'ginger', 'garlic',
    'chilli', 'lemon', 'coriander', 'spinach', 'cucumber', 'carrot', 'cauliflower', 'cabbage',
    'milk', 'butter', 'paneer', 'cheese', 'curd', 'ghee', 'cream',
    'rice', 'wheat', 'flour', 'atta', 'maida', 'besan', 'sooji', 'sugar', 'salt', 'oil',
    'dal', 'pulses', 'lentils', 'tea', 'coffee', 'biscuit', 'biscuits', 'cookies',
    'chips', 'noodles', 'maggi', 'chocolate', 'chocolates', 'soap', 'detergent',
    'shampoo', 'toothpaste', 'bread', 'eggs', 'sauce', 'ketchup', 'jam', 'honey',
    'amul', 'lays', 'kurkure', 'cadbury', 'nestle', 'britannia', 'parle', 'tata',
    'fortune', 'aashirvaad', 'dettol', 'dove', 'colgate', 'surf', 'rin', 'ariel',
    'fresh', 'organic', 'green', 'red', 'white', 'brown', 'sweet', 'spicy'
  ]);

  /**
   * Adds custom vocabulary from products (names, categories).
   */
  addWords(words: string[]) {
    for (const word of words) {
      if (word && word.length > 2) {
        this.vocabulary.add(word.toLowerCase().trim());
      }
    }
  }

  /**
   * Computes standard Levenshtein edit distance between two strings.
   */
  levenshteinDistance(a: string, b: string): number {
    const matrix: number[][] = [];

    for (let i = 0; i <= b.length; i++) {
      matrix[i] = [i];
    }
    for (let j = 0; j <= a.length; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= b.length; i++) {
      for (let j = 1; j <= a.length; j++) {
        if (b.charAt(i - 1) === a.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1, // substitution
            matrix[i][j - 1] + 1,     // insertion
            matrix[i - 1][j] + 1      // deletion
          );
        }
      }
    }

    return matrix[b.length][a.length];
  }

  /**
   * Suggests the closest dictionary match if a word is misspelled (max edit distance 2).
   */
  findClosestWord(input: string): string | null {
    const target = input.toLowerCase().trim();
    if (this.vocabulary.has(target)) {
      return target;
    }

    let minDistance = 3;
    let closest: string | null = null;

    for (const word of this.vocabulary) {
      // Fast length filter
      if (Math.abs(word.length - target.length) > 2) continue;

      const dist = this.levenshteinDistance(target, word);
      if (dist < minDistance) {
        minDistance = dist;
        closest = word;
      }
    }

    return closest;
  }

  /**
   * Corrects a multi-word search phrase.
   */
  correctPhrase(phrase: string): { corrected: string; wasChanged: boolean } {
    const tokens = phrase.trim().split(/\s+/);
    let wasChanged = false;

    const correctedTokens = tokens.map((token) => {
      const match = this.findClosestWord(token);
      if (match && match !== token.toLowerCase()) {
        wasChanged = true;
        return match;
      }
      return token;
    });

    return {
      corrected: correctedTokens.join(' '),
      wasChanged,
    };
  }
}
