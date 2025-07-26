const { HfInference } = require('@huggingface/inference');

const hf = new HfInference(process.env.HUGGINGFACE_API_KEY);

// Model registry for different agent types
const MODELS = {
  sentiment: 'cardiffnlp/twitter-roberta-base-sentiment-latest',
  embeddings: 'sentence-transformers/all-MiniLM-L6-v2',
  textGeneration: 'microsoft/DialoGPT-medium',
  classification: 'facebook/bart-large-mnli',
  emotion: 'j-hartmann/emotion-english-distilroberta-base'
};

class SentimentAnalyzer {
  constructor() {
    this.model = MODELS.sentiment;
  }

  async analyzeSentiment(text) {
    try {
      const result = await hf.textClassification({
        model: this.model,
        inputs: text
      });

      return {
        text,
        sentiment: result[0].label,
        confidence: result[0].score,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Sentiment analysis failed: ${error.message}`);
    }
  }

  async analyzeBatch(texts) {
    try {
      const results = await Promise.all(
        texts.map(text => this.analyzeSentiment(text))
      );

      return {
        results,
        summary: {
          total: results.length,
          positive: results.filter(r => r.sentiment === 'POSITIVE').length,
          negative: results.filter(r => r.sentiment === 'NEGATIVE').length,
          neutral: results.filter(r => r.sentiment === 'NEUTRAL').length
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Batch sentiment analysis failed: ${error.message}`);
    }
  }
}

class TextEmbedder {
  constructor() {
    this.model = MODELS.embeddings;
  }

  async getEmbeddings(text) {
    try {
      const result = await hf.featureExtraction({
        model: this.model,
        inputs: text
      });

      return {
        text,
        embeddings: result,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Embedding generation failed: ${error.message}`);
    }
  }

  cosineSimilarity(vecA, vecB) {
    const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
    const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
    const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));

    return dotProduct / (magnitudeA * magnitudeB);
  }

  async getSimilarity(text1, text2) {
    try {
      const [embedding1, embedding2] = await Promise.all([
        this.getEmbeddings(text1),
        this.getEmbeddings(text2)
      ]);

      const similarity = this.cosineSimilarity(embedding1.embeddings, embedding2.embeddings);

      return {
        text1,
        text2,
        similarity,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Similarity calculation failed: ${error.message}`);
    }
  }
}

class RecommendationEngine {
  constructor() {
    this.embedder = new TextEmbedder();
  }

  async findSimilarItems(query, items, threshold = 0.7) {
    try {
      const queryEmbedding = await this.embedder.getEmbeddings(query);

      const similarities = await Promise.all(
        items.map(async (item) => {
          const itemEmbedding = await this.embedder.getEmbeddings(item.text || item.content);
          const similarity = this.embedder.cosineSimilarity(
            queryEmbedding.embeddings,
            itemEmbedding.embeddings
          );

          return {
            ...item,
            similarity,
            relevant: similarity >= threshold
          };
        })
      );

      const recommendations = similarities
        .filter(item => item.relevant)
        .sort((a, b) => b.similarity - a.similarity);

      return {
        query,
        recommendations,
        total: recommendations.length,
        threshold,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Recommendation generation failed: ${error.message}`);
    }
  }

  async enhanceRecommendations(recommendations) {
    try {
      const enhanced = recommendations.map(rec => ({
        ...rec,
        confidence: this.calculateConfidence(rec.similarity),
        category: this.categorizeRecommendation(rec.similarity),
        rank: recommendations.indexOf(rec) + 1
      }));

      return {
        recommendations: enhanced,
        metadata: {
          total: enhanced.length,
          high_confidence: enhanced.filter(r => r.confidence === 'high').length,
          medium_confidence: enhanced.filter(r => r.confidence === 'medium').length,
          low_confidence: enhanced.filter(r => r.confidence === 'low').length
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Recommendation enhancement failed: ${error.message}`);
    }
  }

  calculateConfidence(similarity) {
    if (similarity >= 0.8) return 'high';
    if (similarity >= 0.6) return 'medium';
    return 'low';
  }

  categorizeRecommendation(similarity) {
    if (similarity >= 0.9) return 'exact_match';
    if (similarity >= 0.7) return 'strong_match';
    if (similarity >= 0.5) return 'moderate_match';
    return 'weak_match';
  }
}

class TextClassifier {
  constructor() {
    this.model = MODELS.classification;
    this.emotionModel = MODELS.emotion;
  }

  async zeroShotClassification(text, labels) {
    try {
      const result = await hf.zeroShotClassification({
        model: this.model,
        inputs: text,
        parameters: { candidate_labels: labels }
      });

      return {
        text,
        classifications: result.labels.map((label, index) => ({
          label,
          score: result.scores[index]
        })),
        predicted_label: result.labels[0],
        confidence: result.scores[0],
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Zero-shot classification failed: ${error.message}`);
    }
  }

  async emotionClassification(text) {
    try {
      const result = await hf.textClassification({
        model: this.emotionModel,
        inputs: text
      });

      return {
        text,
        emotion: result[0].label,
        confidence: result[0].score,
        all_emotions: result,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Emotion classification failed: ${error.message}`);
    }
  }
}

class TextGenerator {
  constructor() {
    this.model = MODELS.textGeneration;
  }

  async generateText(prompt, options = {}) {
    try {
      const result = await hf.textGeneration({
        model: this.model,
        inputs: prompt,
        parameters: {
          max_length: options.max_length || 100,
          temperature: options.temperature || 0.7,
          top_p: options.top_p || 0.9,
          ...options
        }
      });

      return {
        prompt,
        generated_text: result.generated_text,
        options,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Text generation failed: ${error.message}`);
    }
  }
}

// Utility functions
const checkApiKey = () => {
  if (!process.env.HUGGINGFACE_API_KEY) {
    throw new Error('HUGGINGFACE_API_KEY environment variable is required');
  }
};

const formatHuggingFaceError = (error) => {
  return {
    message: error.message,
    status: error.status || 'unknown',
    timestamp: new Date().toISOString()
  };
};

module.exports = {
  SentimentAnalyzer,
  TextEmbedder,
  RecommendationEngine,
  TextClassifier,
  TextGenerator,
  MODELS,
  checkApiKey,
  formatHuggingFaceError,
  hf
};
