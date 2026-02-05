using AutoMapper;
using DocumentFormat.OpenXml.EMMA;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.Reflection;

namespace ManejoPresupuestos.Controllers
{
    public class RecetasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioProductos repositorioProductos;
        private readonly IRepositorioProductoCategorias repositorioProductoCategorias;
        private readonly IRepositorioRecetas repositorioRecetas;
        private readonly IMapper mapper;

        public RecetasController(
            IServicioUsuarios servicioUsuarios,
            IMapper mapper,
            IRepositorioProductos repositorioProductos,
            IRepositorioProductoCategorias repositorioProductoCategorias,
            IRepositorioRecetas repositorioRecetas
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.mapper = mapper;
            this.repositorioProductos = repositorioProductos;
            this.repositorioProductoCategorias = repositorioProductoCategorias;
            this.repositorioRecetas = repositorioRecetas;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var param = new ParametroObtenerRecetas()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };
            var recetas = await repositorioRecetas.ObtenerTodos(param);
            return View(recetas);
        }

        [HttpGet]
        public async Task<IActionResult> RecetaEditor()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var param = new ParametroObtenerInventariosParaReceta()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };

            var inventariosReceta = await repositorioRecetas.ObtenerInventariosReceta(param);

            return View(inventariosReceta);
        }

        [HttpGet]
        public async Task<IActionResult> RecetaEditorUpdate(int recetaId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var receta = await repositorioRecetas.ObtenerRecetaPorId(recetaId, usuarioId);

            if (receta is null || receta.RecetaId == 0)
                return RedirectToAction("NoEncontrado", "Home");

            // Inventarios ya asignados a la receta (lado derecho)
            var recetaInventarios = await repositorioRecetas.ObtenerRecetaInventarioNecesario(receta.RecetaId, usuarioId);

            // Inventarios totales (lado izquierdo)
            var param = new ParametroObtenerInventariosParaReceta()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };
            var inventariosReceta = await repositorioRecetas.ObtenerInventariosReceta(param);

            // Filtrar los inventarios disponibles (solo los NO seleccionados)
            var idsSeleccionados = recetaInventarios.Select(x => x.InventarioId).ToHashSet();
            var inventariosDisponibles = inventariosReceta.Where(x => !idsSeleccionados.Contains(x.InventarioId)).ToList();

            // Guardar info en ViewBag
            // fallback por si todavía hay recetas viejas con TiempoImpresion string
            int tiempoImp = receta.TiempoImpresionMin;
            if (tiempoImp <= 0 && !string.IsNullOrWhiteSpace(receta.TiempoImpresion) && int.TryParse(receta.TiempoImpresion, out var tmpImp))
            {
                tiempoImp = tmpImp;
            }
            int tiempoPost = receta.TiempoPostMin;

            ViewBag.Receta = new
            {
                Id = receta.RecetaId,
                Nombre = receta.Nombre,
                TiempoImpresionMin = tiempoImp,
                TiempoPostMin = tiempoPost
            };

            // Mandar los materiales ya seleccionados
            ViewBag.MaterialesSeleccionados = recetaInventarios;

            return View("RecetaEditor", inventariosDisponibles);
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerProductos()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var productos = await repositorioProductos.ObtenerTodos(usuarioId);
            return Json(productos);
        }

        [HttpPost]
        public async Task<IActionResult> AsignarProductoAReceta([FromBody] AsignarProductoViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            // fallback por si llega legacy
            var tiempoImp = modelo.TiempoImpresionMin;
            if (tiempoImp <= 0 && !string.IsNullOrWhiteSpace(modelo.Tiempo) && int.TryParse(modelo.Tiempo, out var tmpImp))
            {
                tiempoImp = tmpImp;
            }

            var param = new ParametroAlterarReceta()
            {
                LoginId = usuarioId,
                ElementoAlterarId = modelo.RecetaId,
                ProductoId = modelo.ProductoId,
                Actualizar = 1,
                Borrar = 0,
                Nombre = modelo.Nombre,

                // legacy (opcional)
                Tiempo = tiempoImp.ToString(),

                // nuevos
                TiempoImpresionMin = tiempoImp,
                TiempoPostMin = modelo.TiempoPostMin
            };

            var result = await repositorioRecetas.CrearReceta(param);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                return Json(new { result = "fail", message = "No se pudo asignar el producto: " + result.message });
            }

            return Json(new { result = "success", message = "Producto asignado correctamente" });
        }

        [HttpPost]
        public async Task<IActionResult> RecetaEditorGuardar([FromBody] CrearRecetaViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            int productoIdFinal = modelo.ProductoId;

            if (modelo.RecetaId != 0 && productoIdFinal == 0)
            {
                var recetaDb = await repositorioRecetas.ObtenerRecetaPorId(modelo.RecetaId, usuarioId);
                if (recetaDb is null || recetaDb.RecetaId == 0)
                {
                    return Json(new
                    {
                        result = "fail",
                        message = "Receta no encontrada para actualizar."
                    });
                }

                productoIdFinal = recetaDb.ProductoId; // ✅ conservar
            }

            var param = new ParametroAlterarReceta()
            {
                LoginId = usuarioId,
                Nombre = modelo.Nombre,
                ProductoId = productoIdFinal,

                // legacy (opcional)
                Tiempo = (modelo.TiempoImpresionMin > 0 ? modelo.TiempoImpresionMin.ToString() : (modelo.Tiempo ?? "0")),

                // nuevos
                TiempoImpresionMin = modelo.TiempoImpresionMin,
                TiempoPostMin = modelo.TiempoPostMin,

                ElementoAlterarId = modelo.RecetaId,
                Actualizar = (modelo.RecetaId != 0 ? 1 : 0),
                Borrar = 0
            };

            var crearReceta = await repositorioRecetas.CrearReceta(param);
            if (crearReceta.result != ResultProcedureType.SUCCESS)
            {
                return Json(new
                {
                    result = "fail",
                    message = "Receta no modificada: " + crearReceta.message
                });
            }

            var json = JsonConvert.SerializeObject(modelo.Inventarios, new JsonSerializerSettings
            {
                ContractResolver = new DefaultContractResolver(),
                Formatting = Formatting.None
            });

            var paramRelation = new ParametroCrearRelacionRecetaInventario()
            {
                LoginId = usuarioId,
                RecetaId = crearReceta.elementoId,
                Json = json
            };

            var crearRecetaRelacion = await repositorioRecetas.CrearRelacionRecetaInventario(paramRelation);
            if (crearRecetaRelacion.result != ResultProcedureType.SUCCESS)
            {
                return Json(new
                {
                    result = "fail",
                    message = "Receta no creada: " + crearRecetaRelacion.message
                });
            }

            return Json(new
            {
                result = "success",
                message = "Receta guardada con exito"
            });
        }

        [HttpPost]
        public async Task<IActionResult> ReplicarReceta([FromBody] ReplicarRecetaViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var res = await repositorioRecetas.ReplicarReceta(
                recetaIdOrigen: modelo.RecetaIdOrigen,
                loginId: usuarioId,
                nombreNuevo: modelo.NombreNuevo
            );

            if (res.result != ResultProcedureType.SUCCESS)
                return Json(new { result = "fail", message = res.message });

            return Json(new { result = "success", recetaId = res.elementoId });
        }

        [HttpPost]
        public async Task<IActionResult> DesactivarReceta([FromBody] DesactivarRecetaViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var res = await repositorioRecetas.DesactivarReceta(modelo.RecetaId, usuarioId);

            if (res.result != ResultProcedureType.SUCCESS)
                return Json(new { result = "fail", message = res.message });

            return Json(new { result = "success", message = "Receta desactivada" });
        }

    }
}
