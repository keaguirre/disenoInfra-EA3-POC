from flask import Flask, request, jsonify

app = Flask(__name__)

# Base de datos simulada en memoria
saldos = {
    "usuario1": 10000,
    "usuario2": 15000,
    "usuario3": 5000
}

@app.route('/saldo/<usuario>', methods=['GET'])
def obtener_saldo(usuario):
    if usuario not in saldos:
        saldos[usuario] = 100000  # saldo inicial fijo

    return jsonify({
        "usuario": usuario,
        "saldo": saldos[usuario]
    })

@app.route('/pago', methods=['POST'])
def procesar_pago():
    data = request.get_json()
    usuario = data.get('usuario')
    monto = data.get('monto')

    if not usuario or monto is None:
        return jsonify({"error": "Se requieren 'usuario' y 'monto'."}), 400

    if usuario not in saldos:
        saldos[usuario] = 100000

    if monto > saldos[usuario]:
        return jsonify({"error": "Saldo insuficiente."}), 400

    saldos[usuario] -= monto

    return jsonify({
        "usuario": usuario,
        "monto_pagado": monto,
        "nuevo_saldo": saldos[usuario]
    })

@app.route('/retiro', methods=['POST'])
def procesar_retiro():
    data = request.get_json()
    usuario = data.get('usuario')
    monto = data.get('monto')

    if not usuario or monto is None:
        return jsonify({"error": "Se requieren 'usuario' y 'monto'."}), 400

    if not isinstance(monto, int) or monto <= 0:
        return jsonify({"error": "El monto debe ser un número entero positivo."}), 400

    if usuario not in saldos:
        saldos[usuario] = 100000

    saldo_actual = saldos[usuario]

    if monto > saldo_actual:
        return jsonify({
            "error": "El monto excede el saldo disponible.",
            "saldo_disponible": saldo_actual
        }), 400

    saldos[usuario] -= monto

    return jsonify({
        "usuario": usuario,
        "monto_retirado": monto,
        "nuevo_saldo": saldos[usuario]
    })


@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
