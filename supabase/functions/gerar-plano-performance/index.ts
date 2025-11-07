// supabase/functions/gerar-plano-performance/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Trata a requisição CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    // 1. PEGAR O INPUT DO APP
    const { sport } = await req.json()
    if (!sport) {
      throw new Error('O nome do "sport" é obrigatório no body.')
    }

    // 2. AUTENTICAR O USUÁRIO
    const authHeader = req.headers.get('Authorization')!
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'Usuário não autenticado.' }), { status: 401, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // =================================================================
    // 3. CHAMAR A API DO GOOGLE AI (GEMINI)
    // =================================================================

    const googleAiKey = Deno.env.get('GOOGLE_AI_KEY')
    if (!googleAiKey) {
      throw new Error('Segredo GOOGLE_AI_KEY não configurado.')
    }

    // 3b. Criar o prompt para o Google AI (O PROMPT MELHORADO)
    const promptParaIA = `
Aja como 'HAVOK', um sistema de IA de elite especializado em performance atlética e parceiro oficial do BLDR CLUB.
Sua missão é criar um plano de treino de performance de 4 dias por semana, em português (Brasil), para um atleta de ${sport}.

O plano deve ser criativo, desafiador e específico para ${sport}, evitando respostas genéricas.
O 'title' deve ser "Plano de Performance: ${sport}".
O 'subtitle' deve ser motivador e claro (ex: "4 dias/semana focado em explosão e agilidade").

Retorne SUA RESPOSTA ÚNICA E ESTRITAMENTE como um objeto JSON, sem '` + "```" + `json' ou qualquer outro texto.
O formato DEVE ser:
{
  "title": "Plano de Performance: ${sport}",
  "subtitle": "Um subtítulo motivador de 1 linha.",
  "planJson": {
    "dia_1": {
      "foco": "Explosão e Potência",
      "exercicios": [
        {
          "nome": "Nome do Exercício",
          "series": "4",
          "reps": "8-10",
          "descanso": "60-90s",
          "observacoes": "Foco na execução explosiva."
        }
      ]
    },
    "dia_2": {
      "foco": "Agilidade e Core",
      "exercicios": [
        {
          "nome": "Nome do Exercício",
          "series": "3",
          "reps": "12-15",
          "descanso": "60s",
          "observacoes": "Mantenha o core ativado."
        }
      ]
    },
    "dia_3": {
      "foco": "Força Funcional (Específico p/ ${sport})",
      "exercicios": [
        {
          "nome": "Nome do Exercício",
          "series": "4",
          "reps": "10",
          "descanso": "90s",
          "observacoes": "Simule o movimento do esporte."
        }
      ]
    },
    "dia_4": {
      "foco": "Prevenção de Lesões e Mobilidade",
      "exercicios": [
        {
          "nome": "Nome do Exercício",
          "series": "2",
          "reps": "15",
          "descanso": "45s",
          "observacoes": "Movimento controlado."
        }
      ]
    }
  }
}
`

    // 3c. Chamar a API do Google AI (Gemini Pro)
    const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini 2.5-flash:generateContent?key=${googleAiKey}`

    const googleAiResponse = await fetch(geminiApiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        "contents": [{ "parts": [{ "text": promptParaIA }] }],
        "safetySettings": [
          { "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE" },
          { "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE" },
          { "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE" },
          { "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE" }
        ],
        "generationConfig": {
          "responseMimeType": "application/json",
        }
      }),
    })

    if (!googleAiResponse.ok) {
      const errorBody = await googleAiResponse.json()
      console.error('Erro da API Google:', errorBody)
      throw new Error(`Erro da API Google: ${JSON.stringify(errorBody.error)}`)
    }

    const aiResponseJson = await googleAiResponse.json()

    // =================================================================
    // 4. EXTRAIR O JSON FORMATADO DA RESPOSTA DO GOOGLE
    // =================================================================

    let aiResponseText: string
    try {
      aiResponseText = aiResponseJson.candidates[0].content.parts[0].text
    } catch (e) {
      console.error("Erro ao extrair o texto da resposta do Google AI:", aiResponseJson)
      throw new Error("A IA retornou uma resposta em formato inesperado.")
    }

    // Converte o *texto* (que é um JSON) em um objeto JSON
    const aiResponseObject = JSON.parse(aiResponseText)

    // =================================================================
    // 5. ENRIQUECER O JSON E RETORNAR PARA O APP
    // =================================================================

    // Agora nós adicionamos os campos lógicos que o app espera
    const finalResponseJson = {
      ...aiResponseObject, // Pega "title", "subtitle", "planJson" da IA
      id: crypto.randomUUID(), // Gera um ID único e real aqui
      sport: sport, // Adiciona o esporte
      sportContextTag: sport.toLowerCase().replaceAll(' ', ''), // Gera o tag
    }

    // 6. RETORNAR O JSON COMPLETO PARA O APP
    return new Response(
      JSON.stringify(finalResponseJson),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )

  } catch (error) {
    // Tratar erros gerais
    console.error('Erro geral na função:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})