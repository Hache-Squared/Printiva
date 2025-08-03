using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class ProductoCreacionViewModel : Producto
    {
        public IEnumerable<SelectListItem> Categorias { get; set; }
    }
}
