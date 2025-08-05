
var ControladorRecetaEditor = {
    listItemsInventariosDisponibles: [],
    listItemsInventariosParaReceta: [],
    inicializarListener: function(url){
        $("#btn-guardar-receta").click(async function () {
            let resultadoReceta = ControladorRecetaEditor.GetInventarioParaReceta();
            if(!resultadoReceta?.esValido){
                alert(resultadoReceta?.mensaje);
                return;
            }
            let nombre = $("#nombre-receta").val();
            let tiempo = $("#tiempo-receta").val();
            if(nombre?.trim() === ""){
                alert("Nombre para receta es requerido");
                return;
            }
            if(tiempo?.trim() === ""){
                alert("Tiempo para receta es requerido");
                return;
            }
            let inventarios = resultadoReceta?.resultados ?? [];
            let inventariosAEnviar = inventarios?.map(x => {
                return {
                    InventarioId: x?.InventarioId,
                    Cantidad:  x?.cantidadRequerida
                }
            })
            console.log({inventariosAEnviar, nombre, tiempo})
            const form = {
                Nombre: nombre,
                Tiempo: tiempo,
                ProductoId: 0,
                Inventarios: inventariosAEnviar
            }
            const respuesta = await fetch(url, {
                method: "POST",
                body: JSON.stringify(form),
                headers: {
                    'Content-type': 'application/json'
                }
            })

            const json = await respuesta.json();
            console.log(json)
            if(json?.result !== "success"){                
                alert(json?.message)
                return;
            }
           
            alert(json?.message)
            window.location.href = '/Recetas';

        })
    },
    inicializarListas: function (listaInventariosDisponibles = [], listInventariosParaReceta = []) {
        this.listItemsInventariosDisponibles = listaInventariosDisponibles;
        let elementosARenderizarInventariosDisponibles = ControladorRecetaEditor.listItemsInventariosDisponibles?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioDisponible(x)
        })

        $("#left").html(elementosARenderizarInventariosDisponibles);

        this.listItemsInventariosParaReceta = listInventariosParaReceta;
        let elementosARenderizarParaReceta = ControladorRecetaEditor.listItemsInventariosParaReceta?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioParaReceta(x)
        })

        $("#right").html(elementosARenderizarParaReceta);
    },
    refrescarListas: function () {
        let elementosARenderizarInventariosDisponibles = ControladorRecetaEditor.listItemsInventariosDisponibles?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioDisponible(x)
        })

        $("#left").html(elementosARenderizarInventariosDisponibles);

        let elementosARenderizarParaReceta = ControladorRecetaEditor.listItemsInventariosParaReceta?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioParaReceta(x)
        })

        $("#right").html(elementosARenderizarParaReceta);

        ControladorRecetaEditor.inicializarRecetaEditor();
    },
    inicializarRecetaEditor: function () {
        let valoresEjemplo = [];
        let items = document.getElementsByClassName("item-list-drag")
        let rightBox = document.getElementById("right")
        let leftBox = document.getElementById("left")


        for (item of items) {
            item.addEventListener("dragstart", function (e) {
                let selected = e.target;
                let data = $(this).data("payload")
                
                rightBox.addEventListener("dragover", function (e) {
                    e.preventDefault();
                })
                rightBox.addEventListener("drop", function (e) {
                    if (selected !== null) {

                        let index = ControladorRecetaEditor.listItemsInventariosDisponibles.findIndex(x => x.InventarioId === data.InventarioId)
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosParaReceta.push(data)
                            ControladorRecetaEditor.listItemsInventariosDisponibles.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                })

                leftBox.addEventListener("dragover", function (e) {
                    e.preventDefault();
                })
                leftBox.addEventListener("drop", function (e) {
                    
                    if (selected !== null) {
                        
                        let index = ControladorRecetaEditor.listItemsInventariosParaReceta.findIndex(x => x.InventarioId === data.InventarioId)
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosDisponibles.push(data)
                            ControladorRecetaEditor.listItemsInventariosParaReceta.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                })


            })
        }
    },
    RenderItemInventarioDisponible: function (item) {

        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Marca:</div>
                        <div class="col-sm-6">${item?.InventarioMarca}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Nombre Material:</div>
                        <div class="col-sm-6">${item?.InventarioNombre}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Color:</div>
                        <div class="col-sm-6">${item?.InventarioColor}</div>
                    </div>
                    
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Unidad:</div>
                        <div class="col-sm-6">${item?.InventarioUnidad}</div>
                    </div>
                </div>
            </div>
        `;
    },
    RenderItemInventarioParaReceta: function (item) {
        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center item-for-inventory">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Marca:</div>
                        <div class="col-sm-6">${item?.InventarioMarca}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Nombre Material:</div>
                        <div class="col-sm-6">${item?.InventarioNombre}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Color:</div>
                        <div class="col-sm-6">${item?.InventarioColor}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">¿Cantidad de material a usar (${item?.InventarioUnidad}) ?: </div>
                        <div class="col-sm-6">
                            <input class="form-control control-value-quantity" type="number" min="0"/>
                        </div>
                    </div>
                </div>
            </div>
        `;
    },
    GetInventarioParaReceta: function () {
        const elementos = document.querySelectorAll('.item-for-inventory');
        const resultado = [];
        const objeto = {
            resultados: [],
            esValido: true,
            mensaje: ""
        }
        let error = false;
        let msg = "";
        elementos.forEach(elemento => {
            const rawData = elemento.getAttribute('data-payload');
            const item = JSON.parse(rawData);

            const inputCantidad = elemento.querySelector('.control-value-quantity');
            let cantidad = 0;
            if (ControladorRecetaEditor.esNumeroMayorACero(inputCantidad.value)) {
                cantidad = parseFloat(inputCantidad.value);
            } else {
                error = true;
                msg = "La cantidad debe ser un numero y mayor a cero"
            }
            item.cantidadRequerida = isNaN(cantidad) ? 0 : cantidad;

            resultado.push(item);
        });

        if(resultado.length === 0){
             error = true;
             msg = "Relacione al menos un inventario a la receta"
        }

        objeto.resultados = resultado;
        objeto.esValido = !error;
        objeto.mensaje = msg;

        return objeto;
        
    },
    esNumeroMayorACero: function(valor) {
        const numero = parseFloat(valor);
        return !isNaN(numero) && numero > 0;
    }

}

