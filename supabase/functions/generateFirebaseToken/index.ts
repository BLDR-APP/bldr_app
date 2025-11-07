// supabase/functions/generateFirebaseToken/index.ts

import { create, Payload, Header } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { importPKCS8 } from "https://deno.land/x/jose@v5.2.0/index.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FIREBASE_PRIVATE_KEY_PEM = Deno.env.get("FIREBASE_PRIVATE_KEY");
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL");
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");

const ISS = FIREBASE_CLIENT_EMAIL!;
const AUD = "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit";

// >>> FUNÇÃO AUXILIAR CORRIGIDA PARA LIMPEZA FORÇADA E RECONSTRUÇÃO PEM <<<
function formatPrivateKey(key: string): string {
  // 1. Converte o Secret (com \\n) para uma string com quebras de linha reais (\n)
  let formattedKey = key.replace(/\\n/g, '\n');

  // 2. Extrai APENAS o conteúdo Base64 (ignora tags e espaços/novas linhas)
  const base64Content = formattedKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, ''); // Remove TODOS os espaços e quebras de linha remanescentes

  // 3. Reconstroi o formato PEM, com quebras de linha LITERAIS, que o 'jose' espera.
  // Esta reconstrução é crucial para que o importPKCS8 funcione sem erros de decodificação.
  return `-----BEGIN PRIVATE KEY-----\n${base64Content}\n-----END PRIVATE KEY-----`;
}
// >>> FIM DA FUNÇÃO AUXILIAR CORRIGIDA <<<


serve(async (req) => {
  // Verifica segredos
  if (!FIREBASE_PRIVATE_KEY_PEM || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PROJECT_ID) {
    return new Response(
      JSON.stringify({ error: "Firebase secrets not configured." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  // Lê o corpo da requisição
  let supabaseUid: string | null = null;
  try {
    const body = await req.json();
    supabaseUid = body.supabase_uid;
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body." }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  if (!supabaseUid) {
    return new Response(
      JSON.stringify({ error: "supabase_uid is required." }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    // >>> CORREÇÃO CRÍTICA: FORMATAR A CHAVE ANTES DE IMPORTAR <<<
    const pemKey = formatPrivateKey(FIREBASE_PRIVATE_KEY_PEM);

    // Importa a chave privada PKCS8. A chave agora está limpa.
    const privateKey = await importPKCS8(pemKey, "RS256");

    const now = Math.floor(Date.now() / 1000);
    const payload: Payload = {
      iss: ISS,
      sub: ISS,
      aud: AUD,
      iat: now,
      exp: now + 600, // 10 minutos
      uid: supabaseUid,
    };

    const header: Header = { alg: "RS256", typ: "JWT" };

    const firebaseToken = await create(header, payload, privateKey);

    return new Response(
      JSON.stringify({ firebaseToken }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Token generation error:", error);
    // Retorna a mensagem de erro detalhada para o Flutter, o que ajuda na depuração
    return new Response(
      JSON.stringify({
        error: "Failed to generate Firebase token.",
        // Retorna o erro específico da biblioteca 'jose' para depuração
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});