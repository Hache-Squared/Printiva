using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Reflection;

namespace ManejoPresupuestos.Controllers
{
    public class ProductosController: Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioProductos repositorioProductos;
        private readonly IRepositorioProductoCategorias repositorioProductoCategorias;
        private readonly IMapper mapper;

        public ProductosController(
            IServicioUsuarios servicioUsuarios,
            IMapper mapper,
            IRepositorioProductos repositorioProductos,
            IRepositorioProductoCategorias repositorioProductoCategorias
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.mapper = mapper;
            this.repositorioProductos = repositorioProductos;
            this.repositorioProductoCategorias = repositorioProductoCategorias;
        }

        [HttpGet]
        public async Task<IActionResult> RecetaEditor()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> RecetaEditorGuardar()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            return RedirectToAction("RecetaEditor");
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var productos = await repositorioProductos.ObtenerTodos(usuarioId);

            return View(productos);
        }

        [HttpGet]
        public async Task<IActionResult> Categorias()
        {
            var categorias = await repositorioProductoCategorias.ObtenerTodos();

            return View(categorias);
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var modelo = new ProductoCreacionViewModel();

            modelo.Categorias = await ObtenerCategorias();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(ProductoCreacionViewModel producto)
        {
            // Validaciones
            var categoria = await repositorioProductoCategorias.ObtenerPorId(producto.ProductoCategoriaId);

            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                producto.Categorias = await ObtenerCategorias();

                return View(producto);
            }

            await repositorioProductos.Crear(producto);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var producto = await repositorioProductos.ObtenerPorId(usuarioId, id);
            if (producto is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var modelo = mapper.Map<ProductoCreacionViewModel>(producto);

            modelo.Categorias = await ObtenerCategorias();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(ProductoCreacionViewModel productoEditar)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var producto = await repositorioProductos.ObtenerPorId(usuarioId, productoEditar.ProductoId);
            if (producto is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            // Validaciones
            var categoria = await repositorioProductoCategorias.ObtenerPorId(productoEditar.ProductoCategoriaId);

            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                return View(productoEditar);
            }

            await repositorioProductos.Actualizar(usuarioId, productoEditar);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var producto = await repositorioProductos.ObtenerPorId(usuarioId, id);
            if (producto is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }
            return View(producto);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarProducto(int productoId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var producto = await repositorioProductos.ObtenerPorId(usuarioId, productoId);
            if (producto is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            await repositorioProductos.Borrar(usuarioId, productoId);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public IActionResult CrearCategoria()
        {
            return View(null);
        }

        [HttpPost]
        public async Task<IActionResult> CrearCategoria(ProductoCategoria categoria)
        {
            if (!ModelState.IsValid)
            {
                return View(categoria);
            }

            await repositorioProductoCategorias.Crear(categoria);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> EditarCategoria(int id)
        {
            var categoria = await repositorioProductoCategorias.ObtenerPorId(id);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(categoria);
        }

        [HttpPost]
        public async Task<IActionResult> EditarCategoria(ProductoCategoria categoriaEditar)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var categoria = await repositorioProductoCategorias.ObtenerPorId(categoriaEditar.ProductoCategoriaId);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                return View(categoriaEditar);
            }

            await repositorioProductoCategorias.Actualizar(usuarioId, categoriaEditar);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarCategoriaForm(int id)
        {
            var categoria = await repositorioProductoCategorias.ObtenerPorId(id);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }
            return View(categoria);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarCategoria(int productoCategoriaId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var categoria = await repositorioProductoCategorias.ObtenerPorId(productoCategoriaId);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            await repositorioProductoCategorias.Borrar(usuarioId, productoCategoriaId);

            return RedirectToAction("Categorias");
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerCategorias()
        {
            var categorias = await repositorioProductoCategorias.ObtenerTodos();

            return categorias.Select(x => new SelectListItem(x.Nombre, x.ProductoCategoriaId.ToString()));
        }
    }
}
