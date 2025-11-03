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
            ViewBag.Receta = new
            {
                Id = receta.RecetaId,
                Nombre = receta.Nombre,
                Tiempo = receta.TiempoImpresion
            };

            // Mandar los materiales ya seleccionados
            ViewBag.MaterialesSeleccionados = recetaInventarios;

            return View("RecetaEditor", inventariosDisponibles);
        }

        [HttpPost]
        public async Task<IActionResult> RecetaEditorGuardar([FromBody] CrearRecetaViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            ParametroAlterarReceta param;
            
            if(modelo.RecetaId != 0)
            {
                param = new ParametroAlterarReceta()
                {
                    LoginId = usuarioId,
                    Nombre = modelo.Nombre,
                    ProductoId = modelo.ProductoId,
                    Tiempo = modelo.Tiempo,
                    ElementoAlterarId = modelo.RecetaId,
                    Actualizar = 1
                };

            }
            else
            {
                param = new ParametroAlterarReceta()
                {
                    LoginId = usuarioId,
                    Nombre = modelo.Nombre,
                    ProductoId = modelo.ProductoId,
                    Tiempo = modelo.Tiempo,
                };
            }



            var crearReceta = await repositorioRecetas.CrearReceta(param);
            if(crearReceta.result != ResultProcedureType.SUCCESS)
            {
                return Json(new
                {
                    result = "fail",
                    message = "Receta no modificada: " + crearReceta.message
                });
            }
            var json = JsonConvert.SerializeObject(modelo.Inventarios, new JsonSerializerSettings
            {
                ContractResolver = new DefaultContractResolver(), // Respeta las mayúsculas
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


            return Json(new {
                result = "success",
                message = "Receta guardada con exito"
            });
        }

    }
}
