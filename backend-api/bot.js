require('dotenv').config();
const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');

// 1. Configuración de credenciales y rutas de red oficiales
const TELEGRAM_TOKEN = '8797998139:AAHhp_YqMU65nbnaKrWjfH0ifS30YkVAMt4'; 
const DIFY_API_KEY = 'app-c8w6yx63TSFehx0k7SUepa4J'; 

// Ruta pública del contenedor de Dify (Puerto 80)
const DIFY_URL = 'http://127.0.0.1/v1/chat-messages';

// 2. Inicializar el Bot de Telegram
const bot = new TelegramBot(TELEGRAM_TOKEN, { polling: true });

// 🛡️ NUEVO: Escudo protector contra microcortes de internet (ECONNRESET)
bot.on('polling_error', (error) => {
    console.log("⚠️ Aviso: Microcorte de red con Telegram detectado. Reintentando de forma automática...", error.code);
});

console.log('🤖 Cajero Virtual "CajaChica Pro" conectado a Telegram y escuchando...');

// Memoria temporal para guardar el hilo de conversación por usuario
const conversaciones = {};

// 3. Lógica principal: Escuchar mensajes y enviarlos a Dify
bot.on('message', async (msg) => {
    const chatId = msg.chat.id;
    const text = msg.text;

    if (!text) return;

    try {
        // Muestra el estado "Escribiendo..." en el celular
        bot.sendChatAction(chatId, 'typing');

        // Recuperamos el ID de la conversación anterior (si existe)
        const currentConversationId = conversaciones[chatId] || "";

        // Enviar la pregunta a Dify con la estructura de Chatflow (Modo Blocking)
        const response = await axios.post(DIFY_URL, {
            inputs: {},
            query: text,
            response_mode: "blocking", // ⬅️ CAMBIO CRUCIAL: Bloquea hasta tener la respuesta completa
            user: `telegram_${chatId}`, 
            conversation_id: currentConversationId 
        }, {
            headers: {
                'Authorization': `Bearer ${DIFY_API_KEY}`,
                'Content-Type': 'application/json'
            }
            // ⬅️ ELIMINADO: responseType: 'stream'
        });

        // En modo blocking, Dify envía un solo JSON estructurado al finalizar
        const data = response.data;

        // Guardar el ID de la conversación para que el LLM tenga memoria
        if (data.conversation_id) {
            conversaciones[chatId] = data.conversation_id;
        }

        // Extraer la respuesta final directamente del objeto
        const respuestaFinal = data.answer;

        // Enviamos el bloque completo a Telegram
        if (respuestaFinal && respuestaFinal.trim()) {
            bot.sendMessage(chatId, respuestaFinal.trim());
        } else {
            bot.sendMessage(chatId, "No encontré resultados o el formato no fue el esperado.");
        }

    } catch (error) {
        console.error('❌ Error detectado al conectar con Dify:');
        if (error.response) {
            console.error('Código de Estado:', error.response.status);
            console.error('Respuesta de error:', error.response.data);
        } else {
            console.error('Mensaje de Error:', error.message);
        }
        bot.sendMessage(chatId, 'Lo siento, el sistema del micromercado está en mantenimiento en este momento.');
    }
});