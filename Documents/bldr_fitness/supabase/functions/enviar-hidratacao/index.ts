// supabase/functions/enviar-lembrete/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import * as djwt from "https://deno.land/x/djwt@v2.8/mod.ts";

/**
 * Função auxiliar para obter um Token de Acesso OAuth2 do Google
 * usando a Chave da Conta de Serviço.
 */
async function getAccessToken() {
  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
  // Os segredos do Supabase armazenam '\n' como texto literal, então substituímos
  const privateKey = (Deno.env.get('FCM_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n');

  if (!clientEmail || !privateKey) {
    throw new Error('Segredos do FCM (FCM_CLIENT_EMAIL ou FCM_PRIVATE_KEY) não estão configurados.');
  }

  const now = Math.floor(Date.now() / 1000);
  const jwt = await djwt.create(
    { alg: 'RS256', typ: 'JWT' }, // Cabeçalho
    { // Payload
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600, // Token válido por 1 hora
      iat: now,
    },
    privateKey, // Chave
  );

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Falha ao obter token de acesso: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

/**
 * Função principal da Edge Function
 */
serve(async (req) => {
  try {
    // 1. Pega os segredos que salvamos
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    if (!projectId) {
      throw new Error('Segredo FCM_PROJECT_ID não está configurado.');
    }

    // 2. Obtém o Token de Acesso OAuth2 para autorizar nosso envio
    const accessToken = await getAccessToken();

    // 3. Conecta ao Supabase (como admin) para ler a tabela 'profiles'
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 4. Busca TODOS os tokens de usuários que ativaram as notificações
    const { data: profiles, error } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token')
      .eq('notifications_enabled', true) // Filtra quem ativou
      .not('fcm_token', 'is', null)       // Garante que temos um token

    if (error) {
      throw error;
    }

    if (!profiles || profiles.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Nenhum usuário com token encontrado.' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // 5. Monta a URL da API V1 do FCM
    const FCM_URL = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // 6. Prepara todas as promessas de envio (uma para cada usuário)
    const sendPromises = profiles.map(profile => {
      // O payload da V1 é um pouco diferente
      const notificationPayload = {
              message: {
                token: profile.fcm_token,
                notification: {
                  // ===== MUDE AQUI =====
                  title: '💧 Lembrete de Hidratação',
                  body: 'Hora de beber água! Lembre-se de se manter hidratado.',
                  // =====================
                },
                android: {
                  notification: {
                    sound: 'default',
                  },
                },
                apns: {
                  payload: {
                    aps: {
                      sound: 'default',
                      badge: 1,
                    },
                  },
                },
              },
            };

      return fetch(FCM_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`, // <-- Autoriza com o Token de Acesso
        },
        body: JSON.stringify(notificationPayload),
      });
    });

    // 7. Envia todas as notificações em paralelo
    await Promise.all(sendPromises);

    return new Response(
      JSON.stringify({ message: `Notificações enviadas para ${profiles.length} usuários.` }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (err) {
    console.error('Erro na Edge Function:', err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});