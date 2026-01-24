using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    public class ImpresorasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioImpresoras repositorioImpresoras;

        public ImpresorasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioImpresoras repositorioImpresoras
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioImpresoras = repositorioImpresoras;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var impresoras = await repositorioImpresoras.ObtenerTodos(usuarioId, true);
            return View(impresoras);
        }

        [HttpGet]
        public IActionResult Crear()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Crear(ImpresoraEdicionViewModel impresora)
        {
            if (!ModelState.IsValid) return View(impresora);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var r = await repositorioImpresoras.Crear(usuarioId, impresora);

            if (r.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError(string.Empty, r.message);
                return View(impresora);
            }

            TempData["Success"] = r.message;
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var imp = await repositorioImpresoras.ObtenerPorId(usuarioId, id);
            if (imp is null) return RedirectToAction("NoEncontrado", "Home");

            var vm = new ImpresoraEdicionViewModel
            {
                ImpresoraId = imp.ImpresoraId,
                Nombre = imp.Nombre,
                Modelo = imp.Modelo,
                Notas = imp.Notas
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Editar([FromForm] ImpresoraEdicionViewModel impresora)
        {
            if (!ModelState.IsValid) return View(impresora);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var r = await repositorioImpresoras.Actualizar(usuarioId, impresora);

            if (r.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError(string.Empty, r.message);
                return View(impresora);
            }

            TempData["Success"] = r.message;
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Borrar(int impresoraId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var r = await repositorioImpresoras.Borrar(usuarioId, impresoraId);

            if (r.result != ResultProcedureType.SUCCESS)
                TempData["Error"] = r.message;
            else
                TempData["Success"] = r.message;

            return RedirectToAction("Index");
        }
    }
}
