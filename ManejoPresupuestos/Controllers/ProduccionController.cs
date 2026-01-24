using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    public class ProduccionController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioPedidos repositorioPedidos;
        private readonly IRepositorioProduccion repositorioProduccion;
        private readonly IRepositorioImpresoras repositorioImpresoras;

        public ProduccionController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioPedidos repositorioPedidos,
            IRepositorioProduccion repositorioProduccion,
            IRepositorioImpresoras repositorioImpresoras
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioPedidos = repositorioPedidos;
            this.repositorioProduccion = repositorioProduccion;
            this.repositorioImpresoras = repositorioImpresoras;
        }

        [HttpGet]
        public async Task<IActionResult> Pedido(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, id);
            if (pedido is null) return RedirectToAction("NoEncontrado", "Home");

            // Seguridad extra: si no existen items de producción aún, intenta inicializar (idempotente)
            await repositorioProduccion.InitPorPedido(usuarioId, id);

            var items = await repositorioProduccion.ObtenerPorPedido(usuarioId, id);
            var estatus = await repositorioProduccion.ObtenerEstatus();

            var impresoras = await repositorioImpresoras.ObtenerTodos(usuarioId, soloActivas: true);
            var vm = new ProduccionPedidoViewModel
            {
                Pedido = pedido,
                Items = items,
                Estatus = estatus,
                Impresoras = impresoras.Select(x => new SelectListItem(x.Nombre, x.ImpresoraId.ToString()))
            };

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> AccionesDisponibles(int produccionItemId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var acciones = await repositorioProduccion.AccionesDisponibles(usuarioId, produccionItemId);
            return Json(acciones);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CambiarEstatusItemAjax(ProduccionCambiarEstatusViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
                return Json(new { ok = false, message = "Datos inválidos." });

            var result = await repositorioProduccion.CambiarEstatusItem(
                usuarioId,
                modelo.ProduccionItemId,
                modelo.HaciaEstatusId,
                modelo.Notas
            );

            if (result.result != ResultProcedureType.SUCCESS)
                return Json(new { ok = false, message = result.message });

            return Json(new { ok = true, message = result.message });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ActualizarItemDatosAjax(ProduccionActualizarDatosViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
                return Json(new { ok = false, message = "Datos inválidos." });

            var result = await repositorioProduccion.ActualizarItemDatos(usuarioId, modelo);

            if (result.result != ResultProcedureType.SUCCESS)
                return Json(new { ok = false, message = result.message });

            return Json(new { ok = true, message = result.message });
        }

        [HttpGet]
        public async Task<IActionResult> RecetasDisponiblesPorItem(int produccionItemId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var recetas = await repositorioProduccion.RecetasDisponiblesPorItem(usuarioId, produccionItemId);
            return Json(recetas);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AsignarRecetaItemAjax(AsignarRecetaItemViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            if (!ModelState.IsValid) return Json(new { ok=false, message="Datos inválidos." });

            var r = await repositorioProduccion.AsignarRecetaItem(usuarioId, modelo.ProduccionItemId, modelo.RecetaId);
            if (r.result != ResultProcedureType.SUCCESS)
                return Json(new { ok=false, message=r.message });

            return Json(new { ok=true, message=r.message });
        }


    }
}
